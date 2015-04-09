//
//  THProgressHandlerTests.m
//  Thoughts
//
//  Created by Daniel García García on 5/2/15.
//  Copyright (c) 2015 Produkt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import "PDKTProgress.h"
#import "TestablePDKTProgress.h"

@interface PDKTProgressTests : XCTestCase
@property (strong,nonatomic) PDKTProgress *progressHandler;
@property (strong,nonatomic) id<PDKTProgressObserver> observer;
@end

@implementation PDKTProgressTests

- (void)setUp {
    [super setUp];
    self.progressHandler = [[PDKTProgress alloc] init];
    self.observer = mockProtocol(@protocol(PDKTProgressObserver));
}

- (void)tearDown {
    [super tearDown];
}

- (void)testUpdateProgress {
    XCTAssertEqual(self.progressHandler.progress, 0);
    
    self.progressHandler.progress = 0.5;
    XCTAssertEqual(self.progressHandler.progress, 0.5);
    
    self.progressHandler.progress = 1;
    XCTAssertEqual(self.progressHandler.progress, 1);
    
    self.progressHandler.progress = 25;
    XCTAssertEqual(self.progressHandler.progress, 1);
    
    self.progressHandler.progress = -1;
    XCTAssertEqual(self.progressHandler.progress, 1);
}

- (void)testInitFakeProgress {
    [self verifyFakeProgressInitUntil:0.49 duration:50 expectedProgessIncrement:0.0098];
    
    self.progressHandler.progress = 0.1;
    [self verifyFakeProgressInitUntil:0.49 duration:50 expectedProgessIncrement:0.0078];
}

- (void)verifyFakeProgressInitUntil:(CGFloat)progressLimit duration:(NSTimeInterval)duration expectedProgessIncrement:(CGFloat)progressIncrement{
    NSTimer *fakeProgressTimerMock = mock([NSTimer class]);
    [given([fakeProgressTimerMock timeInterval]) willReturnFloat:1];
    self.progressHandler.fakeProgressTimer = fakeProgressTimerMock;
    [self.progressHandler startFakeProgressUntil:progressLimit withDuration:duration];
    [MKTVerify(fakeProgressTimerMock) fire];
    XCTAssertEqual(self.progressHandler.fakeProgressLimit, progressLimit);
    XCTAssertEqual([@(self.progressHandler.fakeProgressIncrement) floatValue], [@(progressIncrement) floatValue]);
}

- (void)testInvalidateTimerWhenProgressUpdatesManually {
    NSTimer *fakeProgressTimerMock = mock([NSTimer class]);
    [given([fakeProgressTimerMock isValid]) willReturnBool:YES];
    self.progressHandler.fakeProgressTimer = fakeProgressTimerMock;
    self.progressHandler.progress = 0.1;
    [MKTVerify(fakeProgressTimerMock) invalidate];
}

- (void)testAvoidTimerInvalidatesItselfOnUpdate {
    NSTimer *fakeProgressTimerMock = mock([NSTimer class]);
    [given([fakeProgressTimerMock isValid]) willReturnBool:YES];
    self.progressHandler.fakeProgressTimer = fakeProgressTimerMock;
    [self.progressHandler startFakeProgressUntil:1 withDuration:10];
    [self.progressHandler updateFakeProgress];
    [MKTVerifyCount(fakeProgressTimerMock, never()) invalidate];
}

- (void)testUpdateFakeProgress {
    TestablePDKTProgress *progressHandler = [[TestablePDKTProgress alloc]init];
    progressHandler.fakeProgressLimit = 0.49;
    progressHandler.fakeProgressIncrement = 0.1;
    
    [progressHandler updateFakeProgress];
    XCTAssertEqual(progressHandler.progress, 0.1);
    
    [progressHandler updateFakeProgress];
    XCTAssertEqual(progressHandler.progress, 0.2);
    
    progressHandler.progress = 0.49;
    [progressHandler updateFakeProgress];
    XCTAssertEqual(progressHandler.progress, 0.49);
}

- (void)testAddObservers {
    [self.progressHandler addObserver:self.observer];
    XCTAssert([self.progressHandler.observers containsObject:self.observer]);
}

- (void)testRemoveObservers {
    [self.progressHandler addObserver:self.observer];
    [self.progressHandler removeObserver:self.observer];
    XCTAssert(![self.progressHandler.observers containsObject:self.observer]);
}

- (void)testNotifyObservers {
    [self.progressHandler addObserver:self.observer];
    self.progressHandler.progress = 0.5;
    [MKTVerify(self.observer) progressHandler:self.progressHandler didUpdateProgress:0.5];
}

- (void)testAddSubprogress {
    PDKTProgress *subprogress = [[PDKTProgress alloc] init];
    [self.progressHandler addSubprogress:subprogress];
    XCTAssert([self.progressHandler.subprogresses containsObject:subprogress]);
    XCTAssert([subprogress.observers containsObject:self.progressHandler]);
}

- (void)testRemoveSubprogress {
    PDKTProgress *subprogress = [[PDKTProgress alloc] init];
    [self.progressHandler addSubprogress:subprogress];
    [self.progressHandler removeSubprogress:subprogress];
    XCTAssert(![self.progressHandler.subprogresses containsObject:subprogress]);
    XCTAssert(![subprogress.observers containsObject:self.progressHandler]);
}

- (void)testProgressBasedOnSubprogresses {
    PDKTProgress *subprogressMock1 = mock([PDKTProgress class]);
    [given([subprogressMock1 progress]) willReturnFloat:0.2];
    [self.progressHandler addSubprogress:subprogressMock1];
    
    XCTAssertEqual([@(self.progressHandler.progress) floatValue], [@(0.2) floatValue]);
    
    PDKTProgress *subprogressMock2 = mock([PDKTProgress class]);
    [given([subprogressMock2 progress]) willReturnFloat:0.5];
    [self.progressHandler addSubprogress:subprogressMock2];
    
    XCTAssertEqual([@(self.progressHandler.progress) floatValue], [@(0.35) floatValue]);
}

- (void)testProgressBasedOnSubprogressesWithWeights {
    PDKTProgress *subprogressMock1 = mock([PDKTProgress class]);
    [given([subprogressMock1 progress]) willReturnFloat:0.2];
    [self.progressHandler addSubprogress:subprogressMock1 withWeight:60];
    
    PDKTProgress *subprogressMock2 = mock([PDKTProgress class]);
    [given([subprogressMock2 progress]) willReturnFloat:0.5];
    [self.progressHandler addSubprogress:subprogressMock2 withWeight:50];
    
    XCTAssertEqual([@(self.progressHandler.progress) floatValue], [@(0.407) floatValue]);
}

- (void)testProgressNotifyObserversWhenSubprogressUpdates {
    PDKTProgress *subprogress1 = [[PDKTProgress alloc] init];
    [self.progressHandler addSubprogress:subprogress1];
    
    PDKTProgress *subprogress2 = [[PDKTProgress alloc] init];
    [self.progressHandler addSubprogress:subprogress2];
    
    id<PDKTProgressObserver> progressObserver = mockProtocol(@protocol(PDKTProgressObserver));
    [self.progressHandler addObserver:progressObserver];
    
    subprogress1.progress = 0.3;
    subprogress2.progress = 0.5;
    
    MKTArgumentCaptor *argument = [MKTArgumentCaptor new];
    [[MKTVerifyCount(progressObserver, times(2)) withMatcher:[argument capture] forArgument:1] progressHandler:self.progressHandler didUpdateProgress:0];
}

@end
