#!/usr/bin/env python3

# Script generates csv for data release
import glob
import os

import pandas as pd
import numpy as np

from sqlalchemy import create_engine

base_path = '/lustre/projects/water/cmwsc/thodson/ambient-loads-update'
out_path = base_path + os.sep + 'data_release'
load_file = out_path + os.sep + 'illinois_ambient_annual_loads_wrtdsk.csv'

long_df = pd.DataFrame()
# read in results as a long dataframe
for filepath in glob.iglob(f'{base_path}/loads/*.sqlite'):

    e = create_engine(f'sqlite:///{filepath}')
    tables = e.table_names()
    filename = os.path.basename(filepath)
    metadata = filename.split('_')
    site = metadata[0]
    parameter = metadata[1]

    if 'wrtds_k_load' in tables:
        print('site: {}; parameter: {}'.format(site, parameter))
        df = pd.read_sql_query(
            """
            SELECT * FROM wrtds_k_load;
            """, e)
        # loads are lognormal, so log 
        df['log_load'] = np.log(df['load'])
        out_df = df.groupby('year').mean()
        log_load_var = df[['year', 'log_load']].groupby('year').var()['log_load']
        log_se = np.sqrt(log_load_var)
        out_df['gse'] = np.exp(log_se)
        out_df = out_df[['load', 'gse', 'n_samples', 'flow_days']]
        out_df = out_df.rename(columns={'load': 'kg',
                                        'n_samples': 'n'})

        out_df['param_cd'] = parameter
        out_df['site_no'] = site

        long_df = long_df.append(out_df)

long_df = long_df.reset_index()
long_df['year'] = long_df['year'].astype(int)

# pivot to wide and save 
wide_df = long_df.pivot(index=['site_no', 'year'],
                        columns='param_cd',
                        values=['kg', 'gse', 'n', 'flow_days'])

# only keep the max of flow_days
flow_days = wide_df.xs('flow_days', axis=1, level=0).max(axis=1)
wide_df = wide_df.drop('flow_days', axis=1, level=0)
wide_df['flow_days'] = flow_days

#format columns
wide_df['flow_days'] = wide_df['flow_days'].astype(int)
wide_df['n'] = wide_df['n'].fillna(0).astype(int)

# rename columns
column_tuples = wide_df.columns.swaplevel().to_flat_index()
wide_df.columns = ['_'.join(i).strip() for i in column_tuples]

# in several cases, WRTDS-K produces unrealistic values; nan them
#threshold = 1e16
#wide_df = wide_df.where(wide_df < 1e16)
#wide_df['00535_kg'] = df['00535_kg'].where(df['00535_kg'] < 1e11)

if not os.path.exists(out_path):
    os.mkdir(out_path)

wide_df.to_csv(load_file, float_format='%.2f')
