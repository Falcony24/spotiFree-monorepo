import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const ArtistCredit = sequelize.define('ArtistCredit', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  artist_count: {
    type: DataTypes.SMALLINT,
    allowNull: false
  },
  ref_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  created: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  edits_pending: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  gid: {
    type: DataTypes.UUID,
    allowNull: false
  }
}, {
  tableName: 'artist_credit',
  timestamps: false,
  indexes: [
    { fields: ['gid'] }
  ]
});

export default ArtistCredit;