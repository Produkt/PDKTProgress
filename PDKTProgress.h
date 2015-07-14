//
//  THProgressHandler.h
//  Thoughts
//
//  Created by Daniel García García on 6/2/15.
//  Copyright (c) 2015 Produkt. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PDKTProgress;

@protocol PDKTProgressObserver <NSObject>
NS_ASSUME_NONNULL_BEGIN
- (void)progressHandler:(PDKTProgress *)progressHandler didUpdateProgress:(CGFloat)progress;
NS_ASSUME_NONNULL_END
@end

@interface PDKTProgress : NSObject
NS_ASSUME_NONNULL_BEGIN
@property (copy,nonatomic) NSString *identifier;
@property (assign,nonatomic) CGFloat progress;
@property (nullable, strong,nonatomic) NSTimer *fakeProgressTimer;
@property (assign,nonatomic,readonly) CGFloat fakeProgressLimit;
@property (assign,nonatomic,readonly) CGFloat fakeProgressIncrement;
@property (copy, readonly) NSDictionary *userInfo;

- (instancetype)initWithUserInfo:(nullable NSDictionary *)userInfoOrNil;
- (void)reset;
- (void)startFakeProgressUntil:(CGFloat)progressLimit withDuration:(NSTimeInterval)progressDuration;
- (void)updateFakeProgress;
- (void)setUserInfoObject:(nullable id)objectOrNil forKey:(nonnull NSString *)key;
NS_ASSUME_NONNULL_END
@end

@interface PDKTProgress (Observer)<PDKTProgressObserver>
NS_ASSUME_NONNULL_BEGIN
@property (nonatomic,readonly) NSArray *observers;

- (void)addObserver:(id<PDKTProgressObserver>)observer;
- (void)removeObserver:(id<PDKTProgressObserver>)observer;
NS_ASSUME_NONNULL_END
@end


@interface PDKTProgress (Subprogress)
NS_ASSUME_NONNULL_BEGIN
@property (nonatomic,readonly) NSArray *subprogresses;

- (void)addSubprogress:(PDKTProgress *)subprogress;
- (void)addSubprogress:(PDKTProgress *)subprogress withWeight:(CGFloat)weight;
- (void)removeSubprogress:(PDKTProgress *)subprogress;
NS_ASSUME_NONNULL_END
@end