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
    
    def _resolve_activity_path(
        self, 
        farmer_id: str, 
        field_id: str, 
        cycle_id: str, 
        activity_type: str = "activities"
    ):
        """Standardized path resolution for hierarchical records"""
        return self.db.collection('farmers').document(farmer_id)\
            .collection('fields').document(field_id)\
            .collection('cycles').document(cycle_id)\
            .collection(activity_type)

    async def save_analysis(
        self,
        farmer_id: str,
        field_id: str,
        cycle_id: str,
        analysis_data: Dict[str, Any]
    ) -> str:
        """Save crop analysis result to hierarchical path"""
        try:
            analysis_ref = self._resolve_activity_path(
                farmer_id, field_id, cycle_id, "analyses"
            ).document()
            
            analysis_data['timestamp'] = datetime.utcnow()
            analysis_ref.set(analysis_data)
            
            logger.info(f"Saved (H) analysis: {analysis_ref.id} | Field: {field_id}")
            return analysis_ref.id
            
        except Exception as e:
            logger.error(f"Failed to save hierarchical analysis: {str(e)}")
            raise

    async def save_prediction(
        self,
        farmer_id: str,
        field_id: str,
        cycle_id: str,
        prediction_data: Dict[str, Any]
    ) -> str:
        """Save hierarchical yield prediction"""
        try:
            prediction_ref = self._resolve_activity_path(
                farmer_id, field_id, cycle_id, "predictions"
            ).document()
            
            prediction_data['prediction_date'] = datetime.utcnow()
            prediction_ref.set(prediction_data)
            
            logger.info(f"Saved (H) prediction: {prediction_ref.id} | Field: {field_id}")
            return prediction_ref.id
            
        except Exception as e:
            logger.error(f"Failed to save hierarchical prediction: {str(e)}")
            raise
    
    async def save_feedback(
        self,
        farmer_id: str,
        field_id: str,
        cycle_id: str,
        analysis_id: str,
        feedback_data: Dict[str, Any]
    ) -> str:
        """Save hierarchical farmer feedback"""
        try:
            feedback_ref = self._resolve_activity_path(
                farmer_id, field_id, cycle_id, "feedback"
            ).document()
            
            feedback_data['analysis_id'] = analysis_id
            feedback_data['timestamp'] = datetime.utcnow()
            feedback_ref.set(feedback_data)
            
            logger.info(f"Saved (H) feedback for analysis {analysis_id} | Field: {field_id}")
            return feedback_ref.id
            
        except Exception as e:
            logger.error(f"Failed to save hierarchical feedback: {str(e)}")
            raise
    
    async def get_farmer_history(
        self,
        farmer_id: str,
        field_id: Optional[str] = None,
        cycle_id: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Get farmer's hierarchical analysis history"""
        try:
            if field_id and cycle_id:
                # Targeted Fetch (Context-Aware)
                analyses = self._resolve_activity_path(farmer_id, field_id, cycle_id, "analyses")\
                    .order_by('timestamp', direction=firestore.Query.DESCENDING)\
                    .limit(limit)\
                    .stream()
            else:
                # Global Fetch (Legacy or Overview)
                # Note: Requires collectionGroup index or manual aggregation
                # For now, we fallback to a simple collection group query if needed
                # or just return empty/warning
                logger.warning("Global history fetch called. Use Plot context for efficiency.")
                return []
            
            return [doc.to_dict() for doc in analyses]
            
        except Exception as e:
            logger.error(f"Failed to get hierarchical history for {farmer_id}: {str(e)}")
            return []
