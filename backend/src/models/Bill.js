const mongoose = require('mongoose');

const billItemSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    default: 1
  },
  cost: {
    type: Number,
    required: true
  }
}, { _id: true });

const itemAssignmentSchema = new mongoose.Schema({
  itemId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  participant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    default: 1
  },
  claimedAt: {
    type: Date,
    default: Date.now
  }
}, { _id: true });

const billSchema = new mongoose.Schema({
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  imageUrl: {
    type: String,
    required: true
  },
  participants: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  items: [billItemSchema],
  totalAmount: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    enum: ['uploaded', 'processing', 'processed', 'split', 'finalized'],
    default: 'uploaded'
  },
  assignmentMode: {
    type: String,
    enum: ['not_set', 'uploader_assigns', 'self_select'],
    default: 'not_set'
  },
  itemAssignments: [itemAssignmentSchema],
  shares: [{
    participant: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    amount: {
      type: Number,
      default: 0
    }
  }],
  participantsFinished: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  restaurant: {
    name: String,
    type: {
      type: String,
      enum: ['restaurant', 'bar'],
      default: 'restaurant'
    }
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Calculate total amount from items
billSchema.methods.calculateTotal = function() {
  this.totalAmount = this.items.reduce((sum, item) => {
    return sum + (item.cost * item.quantity);
  }, 0);
  return this.totalAmount;
};

// Calculate shares based on item assignments
billSchema.methods.calculateShares = function() {
  const sharesMap = new Map();

  // Initialize shares for all participants
  this.participants.forEach(participantId => {
    sharesMap.set(participantId.toString(), 0);
  });

  // Calculate shares based on assignments
  this.itemAssignments.forEach(assignment => {
    const item = this.items.id(assignment.itemId);
    if (item) {
      const participantId = assignment.participant.toString();
      const itemTotal = item.cost * assignment.quantity;
      const currentAmount = sharesMap.get(participantId) || 0;
      sharesMap.set(participantId, currentAmount + itemTotal);
    }
  });

  // Update shares array
  this.shares = Array.from(sharesMap.entries()).map(([participantId, amount]) => ({
    participant: participantId,
    amount: Math.round(amount * 100) / 100 // Round to 2 decimal places
  }));

  return this.shares;
};

// Check if all items are fully assigned
billSchema.methods.areAllItemsAssigned = function() {
  for (const item of this.items) {
    const assignedQuantity = this.itemAssignments
      .filter(a => a.itemId.toString() === item._id.toString())
      .reduce((sum, a) => sum + a.quantity, 0);

    if (assignedQuantity < item.quantity) {
      return false;
    }
  }
  return true;
};

module.exports = mongoose.model('Bill', billSchema);
