require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

async function seedAdmin() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB Atlas');

    const email = 'admin@aast.edu';
    const password = 'Admin@1234';

    let user = await User.findOne({ email });
    if (user) {
      console.log('Admin user already exists. Updating password and isAdmin...');
      user.password = password; // pre-save hook will hash it automatically!
      user.isAdmin = true;
      user.name = 'Admin';
      user.carPlate = 'ADMIN-01';
      await user.save();
      console.log('✅ Admin user updated successfully');
    } else {
      console.log('Admin user does not exist. Creating...');
      user = await User.create({
        name: 'Admin',
        email,
        password,
        carPlate: 'ADMIN-01',
        isAdmin: true
      });
      console.log('✅ Admin user created successfully');
    }

    console.log('User document:', user);
  } catch (err) {
    console.error('Error seeding admin:', err);
  } finally {
    mongoose.disconnect();
  }
}

seedAdmin();
