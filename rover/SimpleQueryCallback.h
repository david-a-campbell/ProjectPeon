#import "GameObject.h"
#import "CartPart.h"
#import "Wheel.h"
#import "Bar.h"

class SimpleQueryCallback : public b2QueryCallback
{
public:
    b2Vec2 pointToTest;
    b2Fixture *fixtureFound;
    b2Fixture *fixtureNotToReport;
    
    SimpleQueryCallback(const b2Vec2& point, b2Fixture *notFix)
    {
        pointToTest = point;
        fixtureFound = nil;
        fixtureNotToReport = notFix;
    }
    
    bool ReportFixture(b2Fixture *fixture) 
    {
        GameObject *object = (GameObject*)fixture->GetBody()->GetUserData();
        CartPart *cartPart = (CartPart*)fixture->GetUserData();
        
        if (fixtureNotToReport && fixture->GetBody() == fixtureNotToReport->GetBody())
        {
            return true;
        }
        
        if (fixture->IsSensor() && [[cartPart class] isSubclassOfClass:[Wheel class]])
        {
            return true;
        }
        
        if (fixture->GetFilterData().categoryBits == kCollideNoneCat)
        {
            return true;
        }
        
        if (object.gameObjectType == kPlayerCartType && cartPart.gameObjectType != kShockPartType)
        {
            if (fixture->TestPoint(pointToTest))
            {
                if (fixture->IsSensor() && cartPart.gameObjectType == kBarPartType)
                {
                    fixture = [(Bar*)cartPart fixture];
                }
                fixtureFound = fixture;
                return false;
            }
        }
        return true;
    }        
};
