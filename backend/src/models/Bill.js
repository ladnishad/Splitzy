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
    enum: ['uploaded', 'processing', 'processed', 'split'],
    default: 'uploaded'
  },
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

module.exports = mongoose.model('Bill', billSchema);
