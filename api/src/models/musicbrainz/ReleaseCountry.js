import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const ReleaseCountry = sequelize.define('ReleaseCountry', {
  release: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  country: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  date_year: DataTypes.SMALLINT,
  date_month: DataTypes.SMALLINT,
  date_day: DataTypes.SMALLINT
}, {
  tableName: 'release_country',
  timestamps: false
});

export default ReleaseCountry;