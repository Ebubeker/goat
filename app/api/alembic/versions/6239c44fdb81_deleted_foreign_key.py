"""deleted foreign key

Revision ID: 6239c44fdb81
Revises: 51eac9c9c842
Create Date: 2022-03-10 17:28:46.254542

"""
from alembic import op
import sqlalchemy as sa
import geoalchemy2
import sqlmodel  



# revision identifiers, used by Alembic.
revision = '6239c44fdb81'
down_revision = '51eac9c9c842'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint('reached_poi_heatmap_poi_uid_fkey', 'reached_poi_heatmap', schema='customer', type_='foreignkey')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_foreign_key('reached_poi_heatmap_poi_uid_fkey', 'reached_poi_heatmap', 'poi', ['poi_uid'], ['id'], source_schema='customer', referent_schema='basic', ondelete='CASCADE')
    # ### end Alembic commands ###