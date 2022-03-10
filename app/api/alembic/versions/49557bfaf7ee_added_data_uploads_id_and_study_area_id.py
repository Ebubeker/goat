"""added data uploads id and study_area id

Revision ID: 49557bfaf7ee
Revises: 3a7b4057398a
Create Date: 2022-03-02 16:17:49.689581

"""
from alembic import op
import sqlalchemy as sa
import geoalchemy2
import sqlmodel  

from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '49557bfaf7ee'
down_revision = '3a7b4057398a'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('study_area', 'setting',
               existing_type=postgresql.JSONB(astext_type=sa.Text()),
               nullable=False,
               schema='basic')
    op.add_column('data_upload', sa.Column('study_area_id', sa.Integer(), nullable=False), schema='customer')
    op.create_foreign_key(None, 'data_upload', 'study_area', ['study_area_id'], ['id'], source_schema='customer', referent_schema='basic')
    op.add_column('scenario', sa.Column('data_upload_ids', sa.ARRAY(sa.Integer()), server_default=sa.text("'{}'::int[]"), nullable=True), schema='customer')
    op.create_index('idx_scenario_data_upload_ids', 'scenario', ['data_upload_ids'], unique=False, schema='customer', postgresql_using='gin')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_index('idx_scenario_data_upload_ids', table_name='scenario', schema='customer', postgresql_using='gin')
    op.drop_column('scenario', 'data_upload_ids', schema='customer')
    op.drop_constraint(None, 'data_upload', schema='customer', type_='foreignkey')
    op.drop_column('data_upload', 'study_area_id', schema='customer')
    op.alter_column('study_area', 'setting',
               existing_type=postgresql.JSONB(astext_type=sa.Text()),
               nullable=True,
               schema='basic')
    # ### end Alembic commands ###