import request from 'supertest';
import app from '../src/app.js';
import { User } from '../src/models/index.js';
import { RefreshToken } from '../src/models/index.js';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

describe('Auth Controller', () => {
  const uniqueSuffix = Date.now();
  let testUser;
  let testPassword = 'password123';
  let refreshTokenString;

  beforeAll(async () => {
    const hashed = await bcrypt.hash(testPassword, 10);
    testUser = await User.create({
      username: `authtest_${uniqueSuffix}`,
      password_hash: hashed
    });
  });

  afterAll(async () => {
    await RefreshToken.destroy({ where: { user_id: testUser.id } });
    await User.destroy({ where: { id: testUser.id } });
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user and return tokens', async () => {
      const username = `newuser_${uniqueSuffix}`;
      const res = await request(app)
        .post('/api/auth/register')
        .send({ username, password: 'newpass123' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');

      const user = await User.findOne({ where: { username } });
      expect(user).not.toBeNull();
      await user.destroy();
    });

    it('should return 400 if username or password missing', async () => {
      const res1 = await request(app)
        .post('/api/auth/register')
        .send({ username: 'onlyname' });
      expect(res1.statusCode).toBe(400);
      expect(res1.body.error).toMatch(/username and password required/);

      const res2 = await request(app)
        .post('/api/auth/register')
        .send({ password: 'onlypass' });
      expect(res2.statusCode).toBe(400);
    });

    it('should return 409 if username already exists', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ username: testUser.username, password: 'somepass' });
      expect(res.statusCode).toBe(409);
      expect(res.body.error).toBe('username already registered');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login with correct credentials and return tokens', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: testUser.username, password: testPassword });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      refreshTokenString = res.body.refreshToken;
    });

    it('should return 401 if user not found', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: 'nonexistent', password: 'any' });
      expect(res.statusCode).toBe(401);
      expect(res.body.error).toBe('Invalid credentials');
    });

    it('should return 401 if password is wrong', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: testUser.username, password: 'wrongpass' });
      expect(res.statusCode).toBe(401);
      expect(res.body.error).toBe('Invalid credentials');
    });

    it('should return 400 if credentials missing', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: testUser.username });
      expect(res.statusCode).toBe(400);
    });
  });

describe('POST /api/auth/refresh', () => {
  let currentRefreshToken;

  beforeEach(async () => {
    await RefreshToken.destroy({ where: { user_id: testUser.id } });

    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ username: testUser.username, password: testPassword });
    currentRefreshToken = loginRes.body.refreshToken;
  });

  it('should refresh tokens with valid refresh token', async () => {
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: currentRefreshToken });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('accessToken');
    expect(res.body).toHaveProperty('refreshToken');
    expect(res.body.refreshToken).not.toBe(currentRefreshToken);
  });

  it('should return 400 if refresh token missing', async () => {
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBe('Refresh token required');
  });

  it('should return 401 if refresh token is invalid (malformed)', async () => {
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: 'invalid.token.string' });
    expect(res.statusCode).toBe(401);
    expect(res.body.error).toBe('Invalid or expired refresh token');
  });

  it('should return 401 if refresh token expired', async () => {
    const expiredToken = jwt.sign(
      { userId: testUser.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: '-1s' }
    );
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: expiredToken });
    expect(res.statusCode).toBe(401);
    expect(res.body.error).toBe('Invalid or expired refresh token');
  });

  it('should return 401 if refresh token already used', async () => {
    const firstRes = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: currentRefreshToken });
    expect(firstRes.statusCode).toBe(200);

    const secondRes = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: currentRefreshToken });
    expect(secondRes.statusCode).toBe(401);
    expect(secondRes.body.error).toBe('Invalid refresh token');
  });
});

  describe('POST /api/auth/logout', () => {
    it('should logout and delete refresh token', async () => {
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ username: testUser.username, password: testPassword });
      const token = loginRes.body.refreshToken;

      const tokenRecord = await RefreshToken.findOne({ where: { token } });
      expect(tokenRecord).not.toBeNull();

      const logoutRes = await request(app)
        .post('/api/auth/logout')
        .send({ refreshToken: token });
      expect(logoutRes.statusCode).toBe(204);

      const deletedRecord = await RefreshToken.findOne({ where: { token } });
      expect(deletedRecord).toBeNull();
    });

    it('should return 204 even if no refresh token provided', async () => {
      const res = await request(app)
        .post('/api/auth/logout')
        .send({});
      expect(res.statusCode).toBe(204);
    });

    it('should return 204 if refresh token does not exist', async () => {
      const res = await request(app)
        .post('/api/auth/logout')
        .send({ refreshToken: 'some-nonexistent-token' });
      expect(res.statusCode).toBe(204);
    });
  });
});