const User = require('../models/User');

// @desc    Get all friends
// @route   GET /api/friends
// @access  Private
const getFriends = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate('friends', 'name email preferences');

    res.status(200).json({
      success: true,
      data: user.friends
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Add a friend
// @route   POST /api/friends
// @access  Private
const addFriend = async (req, res) => {
  try {
    const { friendEmail } = req.body;

    if (!friendEmail) {
      return res.status(400).json({
        success: false,
        message: 'Friend email is required'
      });
    }

    // Find the friend by email
    const friend = await User.findOne({ email: friendEmail.toLowerCase() });

    if (!friend) {
      return res.status(404).json({
        success: false,
        message: 'User not found with this email'
      });
    }

    // Can't add yourself
    if (friend._id.toString() === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'You cannot add yourself as a friend'
      });
    }

    const user = await User.findById(req.user.id);

    // Check if already friends
    if (user.friends.includes(friend._id)) {
      return res.status(400).json({
        success: false,
        message: 'User is already in your friends list'
      });
    }

    // Add friend
    user.friends.push(friend._id);
    await user.save();

    // Populate the newly added friend
    await user.populate('friends', 'name email preferences');

    res.status(200).json({
      success: true,
      data: user.friends
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Remove a friend
// @route   DELETE /api/friends/:friendId
// @access  Private
const removeFriend = async (req, res) => {
  try {
    const { friendId } = req.params;

    const user = await User.findById(req.user.id);

    if (!user.friends.includes(friendId)) {
      return res.status(404).json({
        success: false,
        message: 'Friend not found in your friends list'
      });
    }

    user.friends = user.friends.filter(id => id.toString() !== friendId);
    await user.save();

    await user.populate('friends', 'name email preferences');

    res.status(200).json({
      success: true,
      data: user.friends
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Search users by email
// @route   GET /api/friends/search?email=
// @access  Private
const searchUsers = async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email query parameter is required'
      });
    }

    const users = await User.find({
      email: { $regex: email, $options: 'i' },
      _id: { $ne: req.user.id } // Exclude current user
    })
    .select('name email')
    .limit(10);

    res.status(200).json({
      success: true,
      data: users
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

module.exports = {
  getFriends,
  addFriend,
  removeFriend,
  searchUsers
};
