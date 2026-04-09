import request from 'supertest';
import app from '../src/app.js';
import { User } from '../src/models/index.js';
import jwt from 'jsonwebtoken';
import { Artist, ReleaseGroup, Recording, ArtistCredit } from '../src/models/musicbrainz/index.js';

let authToken;
let userId;

beforeAll(async () => {
  const user = await User.create({ username: 'searchuser', password_hash: 'hash' });
  userId = user.id;
  authToken = jwt.sign({ userId }, process.env.JWT_SECRET);
});

afterAll(async () => {
  await User.destroy({ where: { id: userId } });
});

describe('Search Controller', () => {
  it('should return 400 if q parameter is missing', async () => {
    const res = await request(app)
      .get('/api/search')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBe('Query parameter q required');
  });

  it('should return 400 for invalid type parameter', async () => {
    const res = await request(app)
      .get('/api/search?q=test&type=invalid')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBe('Invalid type parameter');
  });

  it('should search artists only', async () => {
    const res = await request(app)
      .get('/api/search?q=beatles&type=artist')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('artists');
    expect(res.body.artists.data).toBeInstanceOf(Array);
    expect(res.body.albums.data).toHaveLength(0);
    expect(res.body.tracks.data).toHaveLength(0);
  });

  it('should search albums only', async () => {
    const res = await request(app)
      .get('/api/search?q=abbey&type=album')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.albums.data).toBeInstanceOf(Array);
    expect(res.body.artists.data).toHaveLength(0);
    expect(res.body.tracks.data).toHaveLength(0);
  });

  it('should search tracks only', async () => {
    const res = await request(app)
      .get('/api/search?q=come together&type=track')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.tracks.data).toBeInstanceOf(Array);
    expect(res.body.artists.data).toHaveLength(0);
    expect(res.body.albums.data).toHaveLength(0);
  });

  it('should search all types when no type is given', async () => {
    const res = await request(app)
      .get('/api/search?q=love')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('artists');
    expect(res.body).toHaveProperty('albums');
    expect(res.body).toHaveProperty('tracks');
  }, 15000);

  it('should respect limit and offset parameters', async () => {
    const res = await request(app)
      .get('/api/search?q=the&limit=5&offset=10')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.artists.data.length).toBeLessThanOrEqual(5);
  }, 15000);

  it('should clamp limit to 1-100 range', async () => {
    const res = await request(app)
      .get('/api/search?q=rock&limit=200')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.artists.data.length).toBeLessThanOrEqual(100);
  }, 15000);
});