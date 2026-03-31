import './loadEnv.js';
import express from 'express';
import cors from'cors';
import helmet from'helmet';
import morgan from'morgan';
import sequelize from './config/database.js';

import authRoutes from'./routes/auth.js';
import playlistRoutes from'./routes/playlists.js';
import searchRoutes from'./routes/search.js';
import trackRoutes from'./routes/tracks.js';
import albumRoutes from './routes/albums.js';
import favoriteRoutes from './routes/favorites.js';
import artistRoutes from './routes/artist.js';
import userRoutes from './routes/users.js'

import errorHandler from'./middlewares/errorHandler.js';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

app.use('/api/auth', authRoutes);
app.use('/api/playlists', playlistRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/tracks', trackRoutes);
app.use('/api/albums', albumRoutes);
app.use('/api/artists', artistRoutes);
app.use('/api//me', userRoutes);

app.get('/health', (req, res) => res.send('OK'));

app.use(errorHandler);

const PORT = process.env.PORT || 3000;

sequelize.authenticate()
  .then(() => {
    console.log('Database connected');
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch(err => {
    console.error('Unable to connect to database:', err);
});

export default app;