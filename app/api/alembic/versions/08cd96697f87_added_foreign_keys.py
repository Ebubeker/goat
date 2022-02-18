"""added foreign keys

Revision ID: 08cd96697f87
Revises: e5cb614aafa9
Create Date: 2022-02-17 18:06:52.979427

"""
from alembic import op
import sqlalchemy as sa
import geoalchemy2
import sqlmodel  



# revision identifiers, used by Alembic.
revision = '08cd96697f87'
down_revision = 'e5cb614aafa9'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('user', 'active_study_area_id',
               existing_type=sa.INTEGER(),
               nullable=False,
               schema='customer')
    op.create_foreign_key(None, 'user', 'study_area', ['active_study_area_id'], ['id'], source_schema='customer', referent_schema='basic')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint(None, 'user', schema='customer', type_='foreignkey')
    op.alter_column('user', 'active_study_area_id',
               existing_type=sa.INTEGER(),
               nullable=True,
               schema='customer')
    # ### end Alembic commands ###
