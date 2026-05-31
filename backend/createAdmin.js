require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

async function createAdmin() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const email = process.env.ADMIN_EMAIL;
    const password = process.env.ADMIN_PASSWORD;

    if (!email || !password) {
      console.error('❌ ADMIN_EMAIL and ADMIN_PASSWORD must be set in .env');
      process.exit(1);
    }

    const existing = await User.findOne({ email });
    if (existing) {
      if (existing.isAdmin) {
        console.log('ℹ️  Admin user already exists:', email);
      } else {
        existing.isAdmin = true;
        await existing.save();
        console.log('✅ Existing user promoted to admin:', email);
      }
      process.exit(0);
    }

    // User.create triggers the pre-save hook which hashes the password
    await User.create({
      name: 'Admin',
      email,
      password,
      carPlate: 'ADMIN-00',
      idNumber: 'ADMIN-00',
      isAdmin: true,
    });

    console.log('✅ Admin user created successfully:', email);
    process.exit(0);
  } catch (err) {
    console.error('❌ Error creating admin:', err.message);
    process.exit(1);
  }
}

createAdmin();
