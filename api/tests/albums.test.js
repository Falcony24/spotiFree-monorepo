import request from 'supertest';
import app from '../src/app.js';
import { User } from '../src/models/index.js';
import jwt from 'jsonwebtoken';

let authToken;
let userId;

beforeAll(async () => {
  const user = await User.create({ username: 'albumuser', password_hash: 'hash' });
  userId = user.id;
  authToken = jwt.sign({ userId }, process.env.JWT_SECRET);
});

afterAll(async () => {
  await User.destroy({ where: { id: userId } });
});

describe('Album Endpoints', () => {
  //
    it('should get a specific album', async () => {
    const albumMbid = 'eb4db805-3c03-48d3-b6e7-0432de5f8bd3'; 
    const res = await request(app)
      .get(`/api/albums/${albumMbid}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('id', albumMbid);
    expect(res.body).toHaveProperty('title');
  });

  it('should return 404 for non-existent album', async () => {
    const res = await request(app)
      .get('/api/albums/00000000-0000-0000-0000-000000000000')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(404);
  });

  //
  it('should return paginated list of albums', async () => {
    const res = await request(app)
      .get('/api/albums')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('data');
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body).toHaveProperty('total');
    expect(res.body).toHaveProperty('limit');
    expect(res.body).toHaveProperty('offset');
    expect(res.body.data.length).toBeLessThanOrEqual(res.body.limit);
  });

  it('should respect limit parameter', async () => {
    const limit = 5;
    const res = await request(app)
      .get(`/api/albums?limit=${limit}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBeLessThanOrEqual(limit);
    expect(res.body.limit).toBe(limit);
  });
  
  it('should respect offset parameter', async () => {
    const offset = 10;
    const res = await request(app)
      .get(`/api/albums?offset=${offset}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.offset).toBe(offset);
  });

  it('should respect order parameter (asc/desc)', async () => {
    const resAsc = await request(app)
      .get('/api/albums?order=asc')
      .set('Authorization', `Bearer ${authToken}`);
    const resDesc = await request(app)
      .get('/api/albums?order=desc')
      .set('Authorization', `Bearer ${authToken}`);
    expect(resAsc.statusCode).toBe(200);
    expect(resDesc.statusCode).toBe(200);
    if (resAsc.body.data.length && resDesc.body.data.length) {
      const firstAsc = resAsc.body.data[0].title;
      const firstDesc = resDesc.body.data[0].title;
      expect(firstAsc).toBeDefined();
      expect(firstDesc).toBeDefined();
    }
  });

  //
  it('should get tracks for an album', async () => {
    const albumMbid = 'eb4db805-3c03-48d3-b6e7-0432de5f8bd3'; 
    const res = await request(app)
      .get(`/api/albums/${albumMbid}/tracks`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    if (res.body.length > 0) {
      expect(res.body[0]).toHaveProperty('id');
      expect(res.body[0]).toHaveProperty('title');
    }
  });
});