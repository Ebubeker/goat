"""renamed column default_setting to setting

Revision ID: 3a7b4057398a
Revises: e1d37f2ad634
Create Date: 2022-02-24 09:42:49.071643

"""
from alembic import op
import sqlalchemy as sa
import geoalchemy2
import sqlmodel  

from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '3a7b4057398a'
down_revision = 'e1d37f2ad634'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('study_area', sa.Column('setting', postgresql.JSONB(astext_type=sa.Text()), nullable=True), schema='basic')
    op.drop_column('study_area', 'default_setting', schema='basic')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('study_area', sa.Column('default_setting', postgresql.JSONB(astext_type=sa.Text()), autoincrement=False, nullable=False), schema='basic')
    op.drop_column('study_area', 'setting', schema='basic')
    # ### end Alembic commands ###