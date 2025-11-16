const express = require('express');
const multer = require('multer');
const path = require('path');
const {
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
  finalizeBill,
  finishClaiming,
  unlockClaiming
} = require('../controllers/billsController');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, process.env.UPLOAD_DIR || './uploads');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'bill-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  // Accept images only
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB max file size
  }
});

router.use(protect); // All routes are protected

router.post('/manual', createManualBill);
router.post('/upload', upload.single('image'), uploadBill);
router.get('/', getBills);
router.get('/:id', getBill);
router.put('/:id/items', updateBillItems);
router.delete('/:id', deleteBill);

// Assignment and splitting routes
router.put('/:id/assignment-mode', setAssignmentMode);
router.post('/:id/assign-item', assignItem);
router.post('/:id/claim-item', claimItem);
router.delete('/:id/assignments/:assignmentId', removeAssignment);
router.post('/:id/finish-claiming', finishClaiming);
router.post('/:id/unlock-claiming', unlockClaiming);
router.put('/:id/finalize', finalizeBill);

module.exports = router;
