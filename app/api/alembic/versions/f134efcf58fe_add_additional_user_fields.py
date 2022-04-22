"""Add additional user fields

Revision ID: f134efcf58fe
Revises: 910f067bbf0b
Create Date: 2022-04-21 11:04:37.815113

"""
from alembic import op
import sqlalchemy as sa
import geoalchemy2
import sqlmodel  



# revision identifiers, used by Alembic.
revision = 'f134efcf58fe'
down_revision = '910f067bbf0b'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('user', sa.Column('occupation', sa.Text(), nullable=True), schema='customer')
    op.add_column('user', sa.Column('domain', sa.Text(), nullable=True), schema='customer')
    op.add_column('user', sa.Column('newsletter', sa.Boolean(), nullable=True), schema='customer')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('user', 'newsletter', schema='customer')
    op.drop_column('user', 'domain', schema='customer')
    op.drop_column('user', 'occupation', schema='customer')
    # ### end Alembic commands ###
