#import "Box2D.h"
#import "GameObject.h"
#import "CartPart.h"
#import "Wheel.h"
#import "Bar.h"

class ShockQueryCallback : public b2QueryCallback
{
public:
    b2Vec2 pointToTest;
    b2Fixture *fixtureNotToReport;
    b2Fixture *outFixtureList;
    
    ShockQueryCallback(const b2Vec2& point, b2Fixture *notFix)
    {
        outFixtureList = nil;
        pointToTest = point;
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
        if (fixture->GetFilterData().categoryBits == kCollideNoneCat)
        {
            return true;
        }
        if (fixture->IsSensor() && [[cartPart class] isSubclassOfClass:[Wheel class]])
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
                
                b2Fixture* search = outFixtureList;
                while (search)
                {
                    if (search == fixture)
                    {
                        return true;
                    }
                    search = search->punkNextFixture;
                }
                //Add the found fixture to the list
                fixture->punkNextFixture = outFixtureList;
                outFixtureList = fixture;
            }
        }
        return true;
    }
    
    b2Fixture* bestFixture()
    {
        b2Fixture* search = outFixtureList;
        b2Fixture* last = nil;
        
        while (search)
        {
            last = search;
            CartPart *cartPart = (CartPart*)search->GetUserData();
            if ([cartPart isInForeground])
            {
                return search;
            }
            search = search->punkNextFixture;
        }
        return last;
    }
};
