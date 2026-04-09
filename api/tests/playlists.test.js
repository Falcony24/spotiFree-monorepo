import request from 'supertest';
import app from '../src/app.js';
import { User, Playlist, PlaylistTrack } from '../src/models/index.js';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';

let authToken;
let userId;

beforeAll(async () => {
  const user = await User.create({ username: 'playlistuser', password_hash: 'hash' });
  userId = user.id;
  authToken = jwt.sign({ userId }, process.env.JWT_SECRET);
});

beforeEach(async () => {
  const playlists = await Playlist.findAll({ where: { user_id: userId } });
  for (const p of playlists) {
    await PlaylistTrack.destroy({ where: { playlist_id: p.id } });
    await p.destroy();
  }
});

afterAll(async () => {
  await User.destroy({ where: { id: userId } });
});

describe('Playlist Endpoints', () => {
  it('should create a playlist', async () => {
    const res = await request(app)
      .post('/api/playlists')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'My Playlist', description: 'Test', is_public: false });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.name).toBe('My Playlist');
  });

  it('should get user playlists', async () => {
    const playlist = await Playlist.create({ user_id: userId, name: 'Playlist1' });
    const res = await request(app)
      .get('/api/playlists')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBe(1);
    expect(res.body.data[0].name).toBe('Playlist1');
    expect(res.body.data[0].id).toBe(playlist.gid); 
  });

  it('should get a single playlist', async () => {
    const playlist = await Playlist.create({ user_id: userId, name: 'Playlist1' });
    const res = await request(app)
      .get(`/api/playlists/${playlist.gid}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.playlist.name).toBe('Playlist1');
    expect(res.body.playlist.id).toBe(playlist.gid);
  });

  it('should update a playlist', async () => {
    const playlist = await Playlist.create({ user_id: userId, name: 'Old Name' });
    const res = await request(app)
      .put(`/api/playlists/${playlist.gid}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'New Name' });
    expect(res.statusCode).toBe(200);
    expect(res.body.name).toBe('New Name');
    expect(res.body.id).toBe(playlist.gid);
  });

  it('should delete a playlist', async () => {
    const playlist = await Playlist.create({ user_id: userId, name: 'ToDelete' });
    const res = await request(app)
      .delete(`/api/playlists/${playlist.gid}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(204);
    const deleted = await Playlist.findByPk(playlist.id);
    expect(deleted).toBeNull();
  });
});