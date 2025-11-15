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

    await bill.populate('uploadedBy participants', 'name email preferences');

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

    await bill.populate('uploadedBy participants', 'name email preferences');

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
    .populate('uploadedBy participants', 'name email preferences')
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
      .populate('uploadedBy participants', 'name email preferences');

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
    await bill.populate('uploadedBy participants', 'name email preferences');

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

module.exports = {
  createManualBill,
  uploadBill,
  getBills,
  getBill,
  updateBillItems,
  deleteBill
};
