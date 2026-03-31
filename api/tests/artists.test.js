import request from 'supertest';
import app from '../src/app.js';
import { User } from '../src/models/index.js';
import jwt from 'jsonwebtoken';

let authToken;
let userId;

beforeAll(async () => {
  const user = await User.create({ username: 'artistuser', password_hash: 'hash' });
  userId = user.id;
  authToken = jwt.sign({ userId }, process.env.JWT_SECRET);
});

afterAll(async () => {
  await User.destroy({ where: { id: userId } });
});

describe('Artist Endpoints', () => {
  it('should get an artist by MBID', async () => {
    const artistMbid = 'ed962474-bb85-47f9-b108-073184f09bc8'; // example: Rusko
    const res = await request(app)
      .get(`/api/artists/${artistMbid}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('gid', artistMbid);
    expect(res.body).toHaveProperty('name');
  });

  it('should return 404 for non-existent artist', async () => {
    const res = await request(app)
      .get('/api/artists/00000000-0000-0000-0000-000000000000')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(404);
  });

  it('should get albums for an artist', async () => {
    const artistMbid = 'ed962474-bb85-47f9-b108-073184f09bc8';
    const res = await request(app)
      .get(`/api/artists/${artistMbid}/albums`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    if (res.body.data.length > 0) {
      expect(res.body.data[0]).toHaveProperty('id');
      expect(res.body.data[0]).toHaveProperty('title');
    }
  });

  it('should get tracks for an artist', async () => {
    const artistMbid = 'ed962474-bb85-47f9-b108-073184f09bc8';
    const res = await request(app)
      .get(`/api/artists/${artistMbid}/tracks`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    if (res.body.length > 0) {
      expect(res.body[0]).toHaveProperty('id');
      expect(res.body[0]).toHaveProperty('title');
    }
  });
});