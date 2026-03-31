import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const ArtistCreditName = sequelize.define('ArtistCreditName', {
  artist_credit: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  position: {
    type: DataTypes.SMALLINT,
    primaryKey: true
  },
  artist: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  join_phrase: {
    type: DataTypes.TEXT,
    defaultValue: ''
  }
}, {
  tableName: 'artist_credit_name',
  timestamps: false,
  indexes: [
    { fields: ['artist'] }
  ]
});

export default ArtistCreditName;