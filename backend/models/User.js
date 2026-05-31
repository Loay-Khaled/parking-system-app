const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Single source of truth for valid disability types.
// Referenced by admin.js route validation AND the Flutter dropdown options.
const DISABILITY_TYPES = [
  'Mobility Impairment',
  'Visual Impairment',
  'Hearing Impairment',
  'Other',
];

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  carPlate: { type: String, required: true },
  idNumber: { type: String, required: true, unique: true },
  totalBookings: { type: Number, default: 0 },
  totalSpent: { type: Number, default: 0 },
  activePenalties: { type: Number, default: 0 },
  walletBalance: { type: Number, default: 0.00 },
  isAdmin: { type: Boolean, default: false },
  accessibilityPermit: {
    status: {
      type: String,
      enum: ['none', 'pending', 'approved', 'rejected'],
      default: 'none'
    },
    disabilityType: { type: String, default: null },
    conditionDescription: { type: String, default: '' },
    submittedAt: { type: Date },
    reviewedAt: { type: Date },
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    adminNote: { type: String, default: '' },
    notified: { type: Boolean, default: false },
    lastRevokedAt: { type: Date },
    lastRevokedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
  },
  createdAt: { type: Date, default: Date.now },
});

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
module.exports.DISABILITY_TYPES = DISABILITY_TYPES;
