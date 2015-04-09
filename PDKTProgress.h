//
//  THProgressHandler.h
//  Thoughts
//
//  Created by Daniel García García on 6/2/15.
//  Copyright (c) 2015 Produkt. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PDKTProgress;

@protocol PDKTProgressObserver <NSObject>
- (void)progressHandler:(PDKTProgress *)progressHandler didUpdateProgress:(CGFloat)progress;
@end

@interface PDKTProgress : NSObject
@property (copy,nonatomic) NSString *identifier;
@property (assign,nonatomic) CGFloat progress;
@property (strong,nonatomic) NSTimer *fakeProgressTimer;
@property (assign,nonatomic,readonly) CGFloat fakeProgressLimit;
@property (assign,nonatomic,readonly) CGFloat fakeProgressIncrement;
- (void)reset;
- (void)startFakeProgressUntil:(CGFloat)progressLimit withDuration:(NSTimeInterval)progressDuration;
- (void)updateFakeProgress;
@end

@interface PDKTProgress (Observer)<PDKTProgressObserver>
@property (nonatomic,readonly) NSArray *observers;

- (void)addObserver:(id<PDKTProgressObserver>)observer;
- (void)removeObserver:(id<PDKTProgressObserver>)observer;
@end


@interface PDKTProgress (Subprogress)
@property (nonatomic,readonly) NSArray *subprogresses;

- (void)addSubprogress:(PDKTProgress *)subprogress;
- (void)addSubprogress:(PDKTProgress *)subprogress withWeight:(CGFloat)weight;
- (void)removeSubprogress:(PDKTProgress *)subprogress;
@end