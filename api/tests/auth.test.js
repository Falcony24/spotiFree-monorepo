import request from 'supertest';
import app from '../src/app.js';
import { User } from '../src/models/index.js';
import bcrypt from 'bcryptjs';

describe('Auth Endpoints', () => {
  const uniqueSuffix = Date.now();

  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const username = `testuser_${uniqueSuffix}`;
      const res = await request(app)
        .post('/api/auth/register')
        .send({ username, password: 'password123' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      await User.destroy({ where: { username } });
    });

    it('should return 409 if user already exists', async () => {
      const username = `existing_${uniqueSuffix}`;
      await User.create({ username, password_hash: 'hash' });
      const res = await request(app)
        .post('/api/auth/register')
        .send({ username, password: 'password123' });
      expect(res.statusCode).toBe(409);
      await User.destroy({ where: { username } });
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login with correct credentials', async () => {
      const username = `logintest_${uniqueSuffix}`;
      const hashed = await bcrypt.hash('password123', 10);
      await User.create({ username, password_hash: hashed });
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username, password: 'password123' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('accessToken');
      await User.destroy({ where: { username } });
    });

    it('should return 401 with wrong password', async () => {
      const username = `wrong_${uniqueSuffix}`;
      const hashed = await bcrypt.hash('password123', 10);
      await User.create({ username, password_hash: hashed });
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username, password: 'wrong' });
      expect(res.statusCode).toBe(401);
      await User.destroy({ where: { username } });
    });
  });
});