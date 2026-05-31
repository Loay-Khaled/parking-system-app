const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');
const Transaction = require('./models/Transaction');

async function testWallet() {
  console.log('🔄 Connecting to MongoDB...');
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  let testUser = null;
  try {
    // 1. Get or Create a test user
    testUser = await User.findOne({ email: 'wallet-test@aast.edu' });
    if (!testUser) {
      console.log('User not found. Creating a test user...');
      testUser = await User.create({
        name: 'Wallet Tester',
        email: 'wallet-test@aast.edu',
        password: 'TestPassword123',
        carPlate: 'TEST-123',
        idNumber: 'WALLET-TEST-ID',
        walletBalance: 0.00,
      });
    }

    console.log(`👤 Using User: ${testUser.name} (${testUser.email})`);
    console.log(`Original Balance: ${testUser.walletBalance.toFixed(2)} EGP`);

    // Clean up old transactions for this user
    await Transaction.deleteMany({ userId: testUser._id });

    // 2. Test Recharge
    console.log('\n--- Test Recharge ---');
    const rechargeAmount = 150.00;
    testUser.walletBalance += rechargeAmount;
    await testUser.save();
    
    const rechargeTx = await Transaction.create({
      userId: testUser._id,
      amount: rechargeAmount,
      type: 'recharge',
      description: `Test wallet recharge of ${rechargeAmount.toFixed(2)} EGP`,
    });

    console.log(`Recharged: +${rechargeAmount} EGP`);
    console.log(`New Balance: ${testUser.walletBalance.toFixed(2)} EGP`);
    console.log(`Transaction logged: ID: ${rechargeTx._id}, Type: ${rechargeTx.type}`);

    // Validate in DB
    const updatedUser = await User.findById(testUser._id);
    if (updatedUser.walletBalance !== 150.00) {
      throw new Error(`Expected balance 150.00, got ${updatedUser.walletBalance}`);
    }

    // 3. Test Successful Payment
    console.log('\n--- Test Successful Payment ---');
    const paymentAmount = 40.00;
    
    if (updatedUser.walletBalance < paymentAmount) {
      throw new Error('Insufficient funds');
    }
    
    updatedUser.walletBalance -= paymentAmount;
    await updatedUser.save();

    const paymentTx = await Transaction.create({
      userId: updatedUser._id,
      amount: paymentAmount,
      type: 'payment',
      description: `Test payment of ${paymentAmount.toFixed(2)} EGP`,
    });

    console.log(`Paid: -${paymentAmount} EGP`);
    console.log(`New Balance: ${updatedUser.walletBalance.toFixed(2)} EGP`);
    console.log(`Transaction logged: ID: ${paymentTx._id}, Type: ${paymentTx.type}`);

    // Validate in DB
    const afterPaymentUser = await User.findById(testUser._id);
    if (afterPaymentUser.walletBalance !== 110.00) {
      throw new Error(`Expected balance 110.00, got ${afterPaymentUser.walletBalance}`);
    }

    // 4. Test Insufficient Funds
    console.log('\n--- Test Insufficient Funds ---');
    const hugePayment = 500.00;
    console.log(`Attempting to pay ${hugePayment} EGP...`);
    
    if (afterPaymentUser.walletBalance < hugePayment) {
      console.log('❌ Insufficient funds (Expected failure - Success!)');
    } else {
      throw new Error('Wallet allowed spending money that does not exist!');
    }

    // 5. Test History Fetching
    console.log('\n--- Test History Fetching ---');
    const txs = await Transaction.find({ userId: testUser._id }).sort({ createdAt: -1 });
    console.log(`Fetched ${txs.length} transactions:`);
    txs.forEach((tx, idx) => {
      console.log(`  ${idx + 1}. [${tx.type.toUpperCase()}] ${tx.amount} EGP - ${tx.description} (${tx.createdAt})`);
    });

    if (txs.length !== 2) {
      throw new Error(`Expected 2 transactions, got ${txs.length}`);
    }

    console.log('\n✅ All tests passed successfully!');

  } catch (error) {
    console.error('\n❌ Test failed:', error);
  } finally {
    if (testUser) {
      console.log('\n🔄 Cleaning up test user and transactions...');
      await Transaction.deleteMany({ userId: testUser._id });
      await User.deleteOne({ _id: testUser._id });
      console.log('✅ Clean up complete');
    }
    await mongoose.connection.close();
    console.log('🔌 Connection closed');
  }
}

testWallet();
