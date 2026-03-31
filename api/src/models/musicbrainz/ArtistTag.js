import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const ArtistTag = sequelize.define('ArtistTag', {
  artist: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  tag: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  count: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  last_updated: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'artist_tag',
  timestamps: false,
  indexes: [
    { fields: ['tag'] }
  ]
});

export default ArtistTag;