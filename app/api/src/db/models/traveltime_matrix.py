from typing import TYPE_CHECKING, List, Optional

from sqlalchemy import LargeBinary, SmallInteger
from sqlmodel import (
    ARRAY,
    BINARY,
    BigInteger,
    Column,
    Field,
    ForeignKey,
    Integer,
    Relationship,
    SQLModel,
)

if TYPE_CHECKING:
    from .grid import GridCalculation


class TravelTimeMatrixBase(SQLModel):
    id: Optional[int] = Field(sa_column=Column(Integer, primary_key=True, autoincrement=True))
    grid_calculation_id: int = Field(BigInteger, foreign_key="basic.grid_calculation.id", nullable=False, index=True)
    north: int = Field(sa_column=Column(Integer), nullable=False)
    west: int = Field(sa_column=Column(Integer), nullable=False)
    heigth: int = Field(sa_column=Column(SmallInteger), nullable=False)
    width: int = Field(sa_column=Column(SmallInteger), nullable=False)
    costs: bytes = Field(sa_column=Column(LargeBinary), nullable=False)


class TravelTimeMatrixWalking(TravelTimeMatrixBase, table=True):
    __tablename__ = "traveltime_matrix_walking"
    __table_args__ = {"schema": "customer"}

    grid_calculation: "GridCalculation" = Relationship(back_populates="traveltime_matrix_walking")
