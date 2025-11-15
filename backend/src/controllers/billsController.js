const Bill = require('../models/Bill');
const path = require('path');

// @desc    Create a manual bill
// @route   POST /api/bills/manual
// @access  Private
const createManualBill = async (req, res) => {
  try {
    const { participants, restaurantName, items } = req.body;

    if (!restaurantName || !participants || !items || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Restaurant name, participants, and items are required'
      });
    }

    // Parse participants if needed
    let participantIds = Array.isArray(participants) ? participants : JSON.parse(participants);

    // Ensure the creator is in participants
    if (!participantIds.includes(req.user.id)) {
      participantIds.push(req.user.id);
    }

    const bill = await Bill.create({
      uploadedBy: req.user.id,
      imageUrl: '/placeholder.png', // No image for manual bills
      participants: participantIds,
      items: items,
      restaurant: {
        name: restaurantName,
        type: 'restaurant'
      },
      status: 'processed' // Manual bills are already processed
    });

    // Calculate total
    bill.calculateTotal();
    await bill.save();

    await bill.populate('uploadedBy participants', '_id name email preferences');

    res.status(201).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Upload a new bill
// @route   POST /api/bills/upload
// @access  Private
const uploadBill = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Please upload an image'
      });
    }

    const { participants, restaurantName, restaurantType } = req.body;

    // Parse participants if it's a JSON string
    let participantIds = [];
    if (participants) {
      try {
        participantIds = JSON.parse(participants);
      } catch (e) {
        participantIds = Array.isArray(participants) ? participants : [participants];
      }
    }

    // Ensure the uploader is in participants
    if (!participantIds.includes(req.user.id)) {
      participantIds.push(req.user.id);
    }

    const bill = await Bill.create({
      uploadedBy: req.user.id,
      imageUrl: `/uploads/${req.file.filename}`,
      participants: participantIds,
      restaurant: {
        name: restaurantName || 'Unknown',
        type: restaurantType || 'restaurant'
      }
    });

    await bill.populate('uploadedBy participants', '_id name email preferences');

    res.status(201).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get all bills for user
// @route   GET /api/bills
// @access  Private
const getBills = async (req, res) => {
  try {
    const bills = await Bill.find({
      participants: req.user.id
    })
    .populate('uploadedBy participants', '_id name email preferences')
    .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: bills
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get single bill
// @route   GET /api/bills/:id
// @access  Private
const getBill = async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id)
      .populate('uploadedBy participants', '_id name email preferences');

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Check if user is a participant
    const isParticipant = bill.participants.some(
      participant => participant._id.toString() === req.user.id
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view this bill'
      });
    }

    res.status(200).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Update bill items manually
// @route   PUT /api/bills/:id/items
// @access  Private
const updateBillItems = async (req, res) => {
  try {
    const { items } = req.body;

    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Only the uploader can update items
    if (bill.uploadedBy.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Only the bill uploader can update items'
      });
    }

    bill.items = items;
    bill.calculateTotal();
    bill.status = 'processed';

    await bill.save();
    await bill.populate('uploadedBy participants', '_id name email preferences');

    res.status(200).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Delete a bill
// @route   DELETE /api/bills/:id
// @access  Private
const deleteBill = async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Only the uploader can delete
    if (bill.uploadedBy.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Only the bill uploader can delete this bill'
      });
    }

    await bill.deleteOne();

    res.status(200).json({
      success: true,
      message: 'Bill deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Set assignment mode for bill
// @route   PUT /api/bills/:id/assignment-mode
// @access  Private
const setAssignmentMode = async (req, res) => {
  try {
    const { mode } = req.body;

    if (!['uploader_assigns', 'self_select'].includes(mode)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid assignment mode'
      });
    }

    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Only the uploader can set assignment mode
    if (bill.uploadedBy.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Only the bill uploader can set assignment mode'
      });
    }

    bill.assignmentMode = mode;
    await bill.save();
    await bill.populate('uploadedBy participants', '_id name email preferences');

    res.status(200).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Assign item to participant (uploader mode)
// @route   POST /api/bills/:id/assign-item
// @access  Private
const assignItem = async (req, res) => {
  try {
    const { itemId, participantId, quantity } = req.body;

    if (!itemId || !participantId || !quantity) {
      return res.status(400).json({
        success: false,
        message: 'itemId, participantId, and quantity are required'
      });
    }

    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Only uploader can assign in uploader_assigns mode
    if (bill.uploadedBy.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Only the bill uploader can assign items'
      });
    }

    if (bill.assignmentMode !== 'uploader_assigns') {
      return res.status(400).json({
        success: false,
        message: 'Bill is not in uploader_assigns mode'
      });
    }

    // Verify item exists
    const item = bill.items.id(itemId);
    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Item not found'
      });
    }

    // Verify participant is part of the bill
    if (!bill.participants.some(p => p.toString() === participantId)) {
      return res.status(400).json({
        success: false,
        message: 'Participant not part of this bill'
      });
    }

    // Check if total assigned quantity doesn't exceed available
    const currentAssigned = bill.itemAssignments
      .filter(a => a.itemId.toString() === itemId)
      .reduce((sum, a) => sum + a.quantity, 0);

    if (currentAssigned + quantity > item.quantity) {
      return res.status(400).json({
        success: false,
        message: 'Cannot assign more than available quantity'
      });
    }

    // Add assignment
    bill.itemAssignments.push({
      itemId,
      participant: participantId,
      quantity
    });

    // Recalculate shares
    bill.calculateShares();
    await bill.save();
    await bill.populate('uploadedBy participants itemAssignments.participant shares.participant', '_id name email preferences');

    res.status(200).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Claim item (self-select mode)
// @route   POST /api/bills/:id/claim-item
// @access  Private
const claimItem = async (req, res) => {
  try {
    const { itemId, quantity } = req.body;

    if (!itemId || !quantity) {
      return res.status(400).json({
        success: false,
        message: 'itemId and quantity are required'
      });
    }

    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    if (bill.assignmentMode !== 'self_select') {
      return res.status(400).json({
        success: false,
        message: 'Bill is not in self_select mode'
      });
    }

    // Verify user is a participant
    if (!bill.participants.some(p => p.toString() === req.user.id)) {
      return res.status(403).json({
        success: false,
        message: 'You are not a participant of this bill'
      });
    }

    // Verify item exists
    const item = bill.items.id(itemId);
    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Item not found'
      });
    }

    // Check if total claimed quantity doesn't exceed available
    const currentClaimed = bill.itemAssignments
      .filter(a => a.itemId.toString() === itemId)
      .reduce((sum, a) => sum + a.quantity, 0);

    if (currentClaimed + quantity > item.quantity) {
      return res.status(400).json({
        success: false,
        message: 'Not enough quantity available to claim'
      });
    }

    // Add claim
    bill.itemAssignments.push({
      itemId,
      participant: req.user.id,
      quantity
    });

    // Recalculate shares
    bill.calculateShares();
    await bill.save();
    await bill.populate('uploadedBy participants itemAssignments.participant shares.participant', '_id name email preferences');

    res.status(200).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Remove item assignment
// @route   DELETE /api/bills/:id/assignments/:assignmentId
// @access  Private
const removeAssignment = async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    const assignment = bill.itemAssignments.id(req.params.assignmentId);
    if (!assignment) {
      return res.status(404).json({
        success: false,
        message: 'Assignment not found'
      });
    }

    // In uploader_assigns mode, only uploader can remove
    // In self_select mode, user can remove their own claims
    const canRemove =
      bill.uploadedBy.toString() === req.user.id ||
      (bill.assignmentMode === 'self_select' && assignment.participant.toString() === req.user.id);

    if (!canRemove) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to remove this assignment'
      });
    }

    assignment.deleteOne();
    bill.calculateShares();
    await bill.save();
    await bill.populate('uploadedBy participants itemAssignments.participant shares.participant', '_id name email preferences');

    res.status(200).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Finalize bill (lock assignments)
// @route   PUT /api/bills/:id/finalize
// @access  Private
const finalizeBill = async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Only uploader can finalize
    if (bill.uploadedBy.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Only the bill uploader can finalize the bill'
      });
    }

    if (!bill.areAllItemsAssigned()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot finalize: not all items are assigned'
      });
    }

    bill.status = 'finalized';
    bill.calculateShares();
    await bill.save();
    await bill.populate('uploadedBy participants itemAssignments.participant shares.participant', '_id name email preferences');

    res.status(200).json({
      success: true,
      data: bill
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

module.exports = {
  createManualBill,
  uploadBill,
  getBills,
  getBill,
  updateBillItems,
  deleteBill,
  setAssignmentMode,
  assignItem,
  claimItem,
  removeAssignment,
  finalizeBill
};
