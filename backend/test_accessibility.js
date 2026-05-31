const http = require('http');
const mongoose = require('mongoose');
require('dotenv').config();

const BASE_URL = 'localhost';
const PORT = 3000;

function apiRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : '';
    const options = {
      hostname: BASE_URL,
      port: PORT,
      path: '/api' + path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    };

    if (token) {
      options.headers['Authorization'] = 'Bearer ' + token;
    }

    const req = http.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => {
        responseBody += chunk;
      });
      res.on('end', () => {
        try {
          const parsed = responseBody ? JSON.parse(responseBody) : {};
          resolve({
            statusCode: res.statusCode,
            body: parsed,
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            body: responseBody,
          });
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    if (body) {
      req.write(data);
    }
    req.end();
  });
}

async function runTests() {
  console.log('🔄 Connecting to MongoDB to clean up old test users...');
  await mongoose.connect(process.env.MONGODB_URI);
  const User = require('./models/User');
  const Booking = require('./models/Booking');
  const ParkingSpot = require('./models/ParkingSpot');
  
  await User.deleteMany({ email: 'accessibility-test-user@aast.edu' });
  await Booking.deleteMany({ userId: { $in: [await User.findOne({ email: 'accessibility-test-user@aast.edu' })?._id] } });
  
  // Make sure A1 is available and marked as accessibility
  await ParkingSpot.findOneAndUpdate(
    { spotId: 'A1' },
    { status: 'available', isAccessibility: true, accessibilityLabel: 'Wheelchair Access', currentBookingId: null, availableAt: null }
  );

  console.log('✅ MongoDB Cleanup completed.');
  await mongoose.disconnect();

  console.log('\n--- 1. Register Regular User ---');
  const regRes = await apiRequest('POST', '/auth/register', {
    name: 'Access Tester',
    email: 'accessibility-test-user@aast.edu',
    password: 'TestPassword123',
    carPlate: 'ACC-123',
    idNumber: 'ACC-TEST-ID',
  });
  
  if (regRes.statusCode !== 201) {
    console.error('❌ Failed to register regular user:', regRes.body);
    process.exit(1);
  }
  const userToken = regRes.body.token;
  const userId = regRes.body.user.id || regRes.body.user._id;
  console.log(`✅ Regular user registered successfully. Token length: ${userToken.length}`);

  console.log('\n--- 2. Log in Admin User ---');
  const adminRes = await apiRequest('POST', '/auth/login', {
    email: 'admin@aast.edu',
    password: 'Admin@1234',
  });

  if (adminRes.statusCode !== 200) {
    console.error('❌ Failed to login admin user:', adminRes.body);
    process.exit(1);
  }
  const adminToken = adminRes.body.token;
  console.log(`✅ Admin logged in successfully. Token length: ${adminToken.length}`);

  console.log('\n--- 3. Regular User Tries to Book Accessibility Spot A1 (Should fail 403) ---');
  const bookingFailRes = await apiRequest('POST', '/bookings', {
    spotId: 'A1',
    duration: 2,
  }, userToken);

  console.log(`Response Code: ${bookingFailRes.statusCode}`);
  console.log('Response Body:', bookingFailRes.body);
  
  if (bookingFailRes.statusCode === 403 && bookingFailRes.body.requiresPermit === true) {
    console.log('✅ Booking Guard security check passed! Access blocked as expected.');
  } else {
    console.error('❌ Booking Guard security check failed! Expected 403 with requiresPermit: true.');
    process.exit(1);
  }

  console.log('\n--- 4. Admin Grants Accessibility Permit Directly (Admin-Only PATCH) ---');
  const grantRes = await apiRequest('PATCH', `/admin/users/${userId}/accessibility`, {
    status: 'approved',
    disabilityType: 'Mobility Impairment',
    adminNote: 'Verified by admin during integration test.',
  }, adminToken);

  console.log(`Response Code: ${grantRes.statusCode}`);
  console.log('Response Body:', JSON.stringify(grantRes.body).substring(0, 200));

  if (grantRes.statusCode !== 200 || grantRes.body.user?.accessibilityPermit?.status !== 'approved') {
    console.error('❌ Admin grant permit failed. Expected 200 with status approved.');
    process.exit(1);
  }
  console.log('✅ Admin granted accessibility permit successfully.');

  console.log('\n--- 5. GET /accessibility/my-permit (Should be approved) ---');
  const getPermitRes = await apiRequest('GET', '/accessibility/my-permit', null, userToken);
  console.log('Permit Details:', getPermitRes.body);

  if (getPermitRes.body.status !== 'approved') {
    console.error('❌ Expected permit status approved, got:', getPermitRes.body.status);
    process.exit(1);
  }
  console.log('✅ Permit status confirmed approved.');

  console.log('\n--- 6. Verify POST /accessibility/apply returns 403 (self-application disabled) ---');
  const applyRes = await apiRequest('POST', '/accessibility/apply', {
    disabilityType: 'Mobility Impairment',
    conditionDescription: 'Should be blocked by admin-only gate.',
  }, userToken);
  console.log(`Response Code: ${applyRes.statusCode}`);
  if (applyRes.statusCode !== 403) {
    console.error('❌ Expected 403 from disabled apply endpoint, got:', applyRes.statusCode);
    process.exit(1);
  }
  console.log('✅ /accessibility/apply correctly returns 403 (admin-only gate confirmed).');

  console.log('\n--- 7. Regular User Books Accessibility Spot A1 (Should succeed now) ---');
  const bookingSuccessRes = await apiRequest('POST', '/bookings', {
    spotId: 'A1',
    duration: 2,
  }, userToken);

  console.log(`Response Code: ${bookingSuccessRes.statusCode}`);
  console.log('Response Body:', bookingSuccessRes.body);

  if (bookingSuccessRes.statusCode !== 201) {
    console.error('❌ Failed to book spot A1 after admin-granted permit.');
    process.exit(1);
  }
  console.log('✅ Booking created successfully for admin-approved user.');

  console.log('\n--- 8. Admin Revokes Permit (should cancel booking and refund) ---');
  const revokeRes = await apiRequest('PATCH', `/admin/users/${userId}/accessibility`, {
    status: 'none',
    adminNote: 'Revoked during integration test.',
  }, adminToken);
  console.log(`Response Code: ${revokeRes.statusCode}`);
  if (revokeRes.statusCode !== 200) {
    console.error('❌ Admin revoke permit failed:', revokeRes.body);
    process.exit(1);
  }
  console.log('✅ Admin revoked permit. Active bookings on accessibility spots cancelled and refunded.');

  console.log('\n--- 9. User Tries to Book A1 Again After Revocation (Should fail 403) ---');
  // First reset A1 to available (it was just cancelled by revocation)
  const mongoose2 = require('mongoose');
  if (mongoose2.connection.readyState === 0) await mongoose2.connect(process.env.MONGODB_URI);
  const ParkingSpot2 = require('./models/ParkingSpot');
  await ParkingSpot2.findOneAndUpdate({ spotId: 'A1' }, { status: 'available', currentBookingId: null });
  if (mongoose2.connection.readyState !== 0) await mongoose2.disconnect();

  const bookingDeniedRes = await apiRequest('POST', '/bookings', {
    spotId: 'A1',
    duration: 1,
  }, userToken);
  console.log(`Response Code: ${bookingDeniedRes.statusCode}`);
  if (bookingDeniedRes.statusCode !== 403 || bookingDeniedRes.body.requiresPermit !== true) {
    console.error('❌ Expected 403 after revocation, got:', bookingDeniedRes.statusCode);
    process.exit(1);
  }
  console.log('✅ Booking correctly blocked (403) after permit revocation.');

  console.log('\n🌟 End-to-end integration and security checks successfully PASSED! 🌟');
  process.exit(0);
}

runTests().catch(err => {
  console.error('❌ Test failed with error:', err);
  process.exit(1);
});
