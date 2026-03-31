import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const ReleaseUnknownCountry = sequelize.define('ReleaseUnknownCountry', {
  release: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  date_year: DataTypes.SMALLINT,
  date_month: DataTypes.SMALLINT,
  date_day: DataTypes.SMALLINT
}, {
  tableName: 'release_unknown_country',
  timestamps: false
});

export default ReleaseUnknownCountry;