from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from typing import Dict, Any, List, Optional
from datetime import datetime
from loguru import logger
from app.core.config import get_settings
import os


class FirestoreService:
    """Service for interacting with Cloud Firestore"""
    
    def __init__(self):
        settings = get_settings()
        
        # Set credentials
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = settings.google_application_credentials
        
        # Initialize Firestore client
        self.db = firestore.Client(
            project=settings.gcp_project_id,
            database=settings.firestore_database_id
        )
        
        logger.info(f"Firestore service initialized for project: {settings.gcp_project_id}")
    
    async def create_farmer(self, farmer_data: Dict[str, Any]) -> str:
        """Create a new farmer profile"""
        try:
            farmer_ref = self.db.collection('farmers').document()
            farmer_data['created_at'] = datetime.utcnow()
            farmer_ref.set(farmer_data)
            
            logger.info(f"Created farmer profile: {farmer_ref.id}")
            return farmer_ref.id
            
        except Exception as e:
            logger.error(f"Failed to create farmer: {str(e)}")
            raise
    
    async def get_farmer(self, farmer_id: str) -> Optional[Dict[str, Any]]:
        """Get farmer profile by ID"""
        try:
            doc = self.db.collection('farmers').document(farmer_id).get()
            if doc.exists:
                return doc.to_dict()
            return None
            
        except Exception as e:
            logger.error(f"Failed to get farmer {farmer_id}: {str(e)}")
            return None
    
    async def save_analysis(
        self,
        farmer_id: str,
        analysis_data: Dict[str, Any]
    ) -> str:
        """Save crop analysis result"""
        try:
            analysis_ref = self.db.collection('farmers').document(farmer_id)\
                .collection('analyses').document()
            
            analysis_data['timestamp'] = datetime.utcnow()
            analysis_ref.set(analysis_data)
            
            logger.info(f"Saved analysis for farmer {farmer_id}: {analysis_ref.id}")
            return analysis_ref.id
            
        except Exception as e:
            logger.error(f"Failed to save analysis: {str(e)}")
            raise
    
    async def save_prediction(
        self,
        farmer_id: str,
        prediction_data: Dict[str, Any]
    ) -> str:
        """Save yield prediction"""
        try:
            prediction_ref = self.db.collection('farmers').document(farmer_id)\
                .collection('predictions').document()
            
            prediction_data['prediction_date'] = datetime.utcnow()
            prediction_ref.set(prediction_data)
            
            logger.info(f"Saved prediction for farmer {farmer_id}: {prediction_ref.id}")
            return prediction_ref.id
            
        except Exception as e:
            logger.error(f"Failed to save prediction: {str(e)}")
            raise
    
    async def save_feedback(
        self,
        farmer_id: str,
        analysis_id: str,
        feedback_data: Dict[str, Any]
    ) -> str:
        """Save farmer feedback"""
        try:
            feedback_ref = self.db.collection('farmers').document(farmer_id)\
                .collection('feedback').document()
            
            feedback_data['analysis_id'] = analysis_id
            feedback_data['timestamp'] = datetime.utcnow()
            feedback_ref.set(feedback_data)
            
            logger.info(f"Saved feedback for analysis {analysis_id}")
            return feedback_ref.id
            
        except Exception as e:
            logger.error(f"Failed to save feedback: {str(e)}")
            raise
    
    async def get_farmer_history(
        self,
        farmer_id: str,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get farmer's analysis history"""
        try:
            analyses = self.db.collection('farmers').document(farmer_id)\
                .collection('analyses')\
                .order_by('timestamp', direction=firestore.Query.DESCENDING)\
                .limit(limit)\
                .stream()
            
            return [doc.to_dict() for doc in analyses]
            
        except Exception as e:
            logger.error(f"Failed to get history for {farmer_id}: {str(e)}")
            return []
