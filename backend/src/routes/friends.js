const express = require('express');
const { getFriends, addFriend, removeFriend, searchUsers } = require('../controllers/friendsController');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.use(protect); // All routes are protected

router.get('/', getFriends);
router.get('/search', searchUsers);
router.post('/', addFriend);
router.delete('/:friendId', removeFriend);

module.exports = router;
