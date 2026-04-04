"""
FastAPI-compatible ApiError exception for the efficiency plan module.
Drop-in replacement for the JS ApiError utility.
"""

from fastapi import HTTPException


class ApiError(HTTPException):
    """Custom HTTP exception mirroring the JS ApiError class."""

    def __init__(self, status_code: int, message: str):
        super().__init__(status_code=status_code, detail=message)
        self.message = message
