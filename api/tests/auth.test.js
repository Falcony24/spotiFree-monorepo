import request from 'supertest';
import app from '../src/app.js';
import { User } from '../src/models/index.js';
import bcrypt from 'bcryptjs';


describe('Auth Endpoints', () => {
  beforeEach(async () => {
    await User.destroy({ where: {} });
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ username: 'testuser', password: 'password123' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
    });

    it('should return 409 if user already exists', async () => {
      await User.create({ username: 'testuser', password_hash: 'hash' });
      const res = await request(app)
        .post('/api/auth/register')
        .send({ username: 'testuser', password: 'password123' });
      expect(res.statusCode).toBe(409);
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      const hashed = await bcrypt.hash('password123', 10);
      await User.create({ username: 'testuser', password_hash: hashed });
    });

    it('should login with correct credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: 'testuser', password: 'password123' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('accessToken');
    });

    it('should return 401 with wrong password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: 'testuser', password: 'wrong' });
      expect(res.statusCode).toBe(401);
    });
  });
});