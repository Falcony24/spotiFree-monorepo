import request from 'supertest';
import app from '../src/app.js';
import { User } from '../src/models/index.js';
import FavoriteArtist from '../src/models/FavoriteArtist.js';
import FavoriteAlbum from '../src/models/FavoriteAlbum.js';
import FavoriteTrack from '../src/models/FavoriteTrack.js';
import { Recording, ArtistCredit, ReleaseGroup, Artist } from '../src/models/musicbrainz/index.js';
import jwt from 'jsonwebtoken';

let authToken;
let userId;
let testArtist, testAlbum, testTrack;

const ARTIST_MBID = 'ed962474-bb85-47f9-b108-073184f09bc8'; 
const ALBUM_MBID = 'eb4db805-3c03-48d3-b6e7-0432de5f8bd3';  
const TRACK_MBID = 'd3c4b7e2-8f9a-4b5c-9e2f-3a4b5c6d7e8f';  

beforeAll(async () => {
  const user = await User.create({ username: 'favuser', password_hash: 'hash' });
  userId = user.id;
  authToken = jwt.sign({ userId }, process.env.JWT_SECRET);

  testArtist = await Artist.findOne({ where: { gid: ARTIST_MBID } });
  testAlbum = await ReleaseGroup.findOne({ where: { gid: ALBUM_MBID } });
  testTrack = await Recording.findOne({ where: { gid: TRACK_MBID } });

  if (!testArtist || !testAlbum || !testTrack) {
    console.warn('Required MusicBrainz test data missing – some tests will be skipped');
  }
});

afterAll(async () => {
  await User.destroy({ where: { id: userId } });
});

beforeEach(async () => {
  await FavoriteArtist.destroy({ where: { user_id: userId } });
  await FavoriteAlbum.destroy({ where: { user_id: userId } });
  await FavoriteTrack.destroy({ where: { user_id: userId } });
});

describe('Favorite Controller', () => {
  describe('GET /api/favorites', () => {
    it('should return 400 if type missing or invalid', async () => {
      const res = await request(app)
        .get('/api/favorites')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/Invalid or missing type/);

      const res2 = await request(app)
        .get('/api/favorites?type=invalid')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res2.statusCode).toBe(400);
    });

    it('should return empty array if no favorites', async () => {
      const res = await request(app)
        .get('/api/favorites?type=artist')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual([]);
    });

    it('should return favorite artists', async () => {
      if (!testArtist) return; 

      await FavoriteArtist.create({
        user_id: userId,
        artist_id: testArtist.id
      });

      const res = await request(app)
        .get('/api/favorites?type=artist')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveLength(1);
      expect(res.body[0].artist.id).toBe(testArtist.gid);
    });

    it('should return favorite albums', async () => {
      if (!testAlbum) return;

      await FavoriteAlbum.create({
        user_id: userId,
        album_id: testAlbum.id
      });

      const res = await request(app)
        .get('/api/favorites?type=album')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body[0].album.id).toBe(testAlbum.gid);
    });

    it('should return favorite tracks', async () => {
      if (!testTrack) return;

      await FavoriteTrack.create({
        user_id: userId,
        track_id: testTrack.id
      });

      const res = await request(app)
        .get('/api/favorites?type=track')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body[0].track.id).toBe(testTrack.gid);
    });
  });

  describe('POST /api/favorites', () => {
    it('should add artist favorite', async () => {
      if (!testArtist) return;

      const res = await request(app)
        .post('/api/favorites')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ item_type: 'artist', item_mbid: testArtist.gid });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.artist.id).toBe(testArtist.gid);
    });

    it('should add album favorite', async () => {
      if (!testAlbum) return;

      const res = await request(app)
        .post('/api/favorites')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ item_type: 'album', item_mbid: testAlbum.gid });
      expect(res.statusCode).toBe(201);
      expect(res.body.album.id).toBe(testAlbum.gid);
    });

    it('should add track favorite', async () => {
      if (!testTrack) return;

      const res = await request(app)
        .post('/api/favorites')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ item_type: 'track', item_mbid: testTrack.gid });
      expect(res.statusCode).toBe(201);
      expect(res.body.track.id).toBe(testTrack.gid);
    });

    it('should return 409 if already favorite', async () => {
      if (!testArtist) return;

      await request(app)
        .post('/api/favorites')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ item_type: 'artist', item_mbid: testArtist.gid });

      const res = await request(app)
        .post('/api/favorites')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ item_type: 'artist', item_mbid: testArtist.gid });
      expect(res.statusCode).toBe(409);
      expect(res.body.error).toBe('Already favorite');
    });

    it('should return 404 if entity not found', async () => {
      const res = await request(app)
        .post('/api/favorites')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ item_type: 'artist', item_mbid: '00000000-0000-0000-0000-000000000000' });
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /api/favorites/:id', () => {
    it('should delete a favorite by its UUID', async () => {
      if (!testArtist) return;

      const created = await FavoriteArtist.create({
        user_id: userId,
        artist_id: testArtist.id
      });
      const favoriteGid = created.gid;

      const res = await request(app)
        .delete(`/api/favorites/${favoriteGid}?type=artist`)
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.statusCode).toBe(204);

      const deleted = await FavoriteArtist.findByPk(created.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 if favorite not found', async () => {
      const validUuid = '00000000-0000-0000-0000-000000000000'; 
      const res = await request(app)
        .delete(`/api/favorites/${validUuid}?type=artist`)
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.statusCode).toBe(404);
    });
  });
});