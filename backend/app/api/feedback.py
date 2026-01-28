from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.database_service import FirestoreService
from loguru import logger

router = APIRouter(prefix="/api/feedback", tags=["Feedback"])

db_service = FirestoreService()


class FeedbackRequest(BaseModel):
    farmer_id: str
    analysis_id: str
    rating: int  # 1-5 stars
    comment: str
    was_helpful: bool


@router.post("/submit")
async def submit_feedback(feedback: FeedbackRequest):
    """
    Submit farmer feedback on analysis/recommendation
    
    - **farmer_id**: Farmer's unique ID
    - **analysis_id**: ID of the analysis being rated
    - **rating**: 1-5 star rating
    - **comment**: Farmer's comments
    - **was_helpful**: Whether the advice was helpful
    """
    try:
        if not 1 <= feedback.rating <= 5:
            raise HTTPException(status_code=400, detail="Rating must be between 1 and 5")
        
        feedback_id = await db_service.save_feedback(
            farmer_id=feedback.farmer_id,
            analysis_id=feedback.analysis_id,
            feedback_data={
                "rating": feedback.rating,
                "comment": feedback.comment,
                "was_helpful": feedback.was_helpful
            }
        )
        
        logger.info(f"Feedback submitted: {feedback_id}")
        
        return {
            "status": "success",
            "feedback_id": feedback_id,
            "message": "Thank you for your feedback!"
        }
        
    except Exception as e:
        logger.error(f"Feedback submission failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
