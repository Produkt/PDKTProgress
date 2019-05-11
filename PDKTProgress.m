//
//  THProgressHandler.m
//  Thoughts
//
//  Created by Daniel García García on 6/2/15.
//  Copyright (c) 2015 Produkt. All rights reserved.
//


#import "PDKTProgress.h"

static NSString * const subprogressKey = @"subprogress";
static NSString * const subprogressWeightKey = @"subprogressWeight";

@interface PDKTProgress()
@property (assign,nonatomic,readwrite) CGFloat fakeProgressLimit;
@property (assign,nonatomic,readwrite) CGFloat fakeProgressIncrement;
@property (strong,nonatomic) NSHashTable *observersTable;
@property (strong,nonatomic) NSMutableArray *subprogressesWeights;
@property (copy, readwrite) NSDictionary *userInfo;
@end

@interface PDKTProgress (_Observer)
- (void)notifyObserversOfProgressUpdate:(CGFloat)progress;
@end

@interface PDKTProgress (_Subprogress)
- (CGFloat)progressBasedOnSubprogresses;
@end

@implementation PDKTProgress
@synthesize progress = _progress;
@synthesize fakeProgressTimer = _fakeProgressTimer;

- (instancetype)init {
    self = [super init];
    if (self) {
        _observersTable = [NSHashTable weakObjectsHashTable];
        _subprogressesWeights = [NSMutableArray array];
    }
    return self;
}

- (void)reset{
    [self performInManThread:^{
        for (PDKTProgress *subprogress in self.subprogresses) {
            [subprogress reset];
        }
        self->_progress = 0;
    }];
}
- (void)setProgress:(CGFloat)progress{
    if (![self isValidProgess:progress]) {
        return;
    }
    [self performInManThread:^{
        [self updateAndNotifyProgressWithProgress:progress];
        self.fakeProgressTimer = nil;
    }];
}
- (void)updateProgressWithProgress:(CGFloat)progress{
    _progress = progress;    
}
- (void)updateAndNotifyProgressWithProgress:(CGFloat)progress{
    [self updateProgressWithProgress:progress];
    [self notifyObserversOfProgressUpdate:progress];
}
- (BOOL)isValidProgess:(CGFloat)progress{
    return progress>=0 && progress<=1;
}
- (CGFloat)progress{
    __block CGFloat currentProgress = 0;
    [self performInManThread:^{
        if (self.subprogresses.count) {
            currentProgress = [self progressBasedOnSubprogresses];
        }else{
            currentProgress = self->_progress;
        }
    }];
    return currentProgress;
}
- (void)startFakeProgressUntil:(CGFloat)progressLimit withDuration:(NSTimeInterval)progressDuration{
    [self performInManThread:^{
        self.fakeProgressLimit = progressLimit;
        self.fakeProgressIncrement = (progressLimit - self.progress)/(progressDuration/self.fakeProgressTimer.timeInterval);
        [self.fakeProgressTimer fire];
    }];
}
- (void)performInManThread:(void(^)(void))block{
    if ([NSThread isMainThread]) {
        block();
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}
- (void)updateFakeProgress{
    if (self.progress < self.fakeProgressLimit) {
        [self updateAndNotifyProgressWithProgress:(self.progress + self.fakeProgressIncrement)];
    }
}
- (NSTimer *)fakeProgressTimer{
    if (!_fakeProgressTimer) {
        _fakeProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateFakeProgress) userInfo:nil repeats:YES];
    }
    return _fakeProgressTimer;
}
- (void)setFakeProgressTimer:(NSTimer *)fakeProgressTimer{
    if ([_fakeProgressTimer isValid]) {
        [_fakeProgressTimer invalidate];
    }
    _fakeProgressTimer = fakeProgressTimer;
}

- (void)setUserInfoObject:(nullable id)objectOrNil forKey:(nonnull NSString *)key {
    NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    if (!objectOrNil) {
        [mutableUserInfo removeObjectForKey:key];
    } else {
        [mutableUserInfo setObject:objectOrNil forKey:key];
    }
    self.userInfo = [NSDictionary dictionaryWithDictionary:mutableUserInfo];
}

- (NSString *)description{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@> (%f)",NSStringFromClass([self class]),self.progress];
    if (self.subprogresses.count) {
        [description appendFormat:@": %@",self.subprogresses];
    }
    return description;
}
@end

@implementation PDKTProgress (Observer)
- (NSArray *)observers{
    return [self.observersTable allObjects];
}
- (void)addObserver:(id<PDKTProgressObserver>)observer{
    [self.observersTable addObject:observer];
}
- (void)removeObserver:(id<PDKTProgressObserver>)observer{
    [self.observersTable removeObject:observer];
}
- (void)notifyObserversOfProgressUpdate:(CGFloat)progress{
    [self performInManThread:^{
        [self notifyObserversOnCurrentThreadOfProgressUpdate:progress];
    }];
}
- (void)notifyObserversOnCurrentThreadOfProgressUpdate:(CGFloat)progress{
    for (id<PDKTProgressObserver> observer in self.observers) {
        [observer progressHandler:self didUpdateProgress:progress];
    }
}

#pragma mark - THProgressHandlerObserver
- (void)progressHandler:(PDKTProgress *)progressHandler didUpdateProgress:(CGFloat)progress{
    [self notifyObserversOfProgressUpdate:[self progressBasedOnSubprogresses]];
}

@end

@implementation PDKTProgress (Subprogress)

- (NSArray *)subprogresses{
    NSMutableArray *subprogresses = [NSMutableArray array];
    for (NSDictionary *subprogressWeight in self.subprogressesWeights) {
        PDKTProgress *subprogress = subprogressWeight[subprogressKey];
        [subprogresses addObject:subprogress];
    }
    return subprogresses;
}

- (void)addSubprogress:(PDKTProgress *)subprogress{
    NSDictionary *subprogressWeight = @{
                                        subprogressKey : subprogress
                                        };
    [self addSubprogressWeight:subprogressWeight];
}
- (void)addSubprogress:(PDKTProgress *)subprogress withWeight:(CGFloat)weight{
    NSDictionary *subprogressWeight = @{
                                        subprogressKey : subprogress,
                                        subprogressWeightKey : @(weight)
                                        };
    [self addSubprogressWeight:subprogressWeight];
    
}
- (void)addSubprogressWeight:(NSDictionary *)subprogressWeight{
    PDKTProgress *subprogress = subprogressWeight[subprogressKey];
    NSParameterAssert(subprogress);
    [self.subprogressesWeights addObject:subprogressWeight];
    [subprogress addObserver:self];
}
- (void)removeSubprogress:(PDKTProgress *)subprogress{
    [[self.subprogressesWeights copy] enumerateObjectsUsingBlock:^(NSDictionary *subprogressWeight, NSUInteger idx, BOOL *stop) {
        if (subprogressWeight[subprogressKey] == subprogress) {
            [self.subprogressesWeights removeObject:subprogressWeight];
        }
    }];
    [subprogress removeObserver:self];
}
- (CGFloat)progressBasedOnSubprogresses{
    if ([self allSubprogressesHaveWeight]) {
        return [self progressBasedOnWeightedSubprogresses];
    }
    return [self progressBasedOnEquallyWeightedSubprogresses];
}
- (BOOL)allSubprogressesHaveWeight{
    BOOL allSubprogressesHaveWeight = YES;
    for (NSDictionary *subprogressWeight in self.subprogressesWeights) {
        if (!subprogressWeight[subprogressWeightKey]) {
            allSubprogressesHaveWeight = NO;
        }
    }
    return allSubprogressesHaveWeight;
}
- (CGFloat)progressBasedOnWeightedSubprogresses{
    CGFloat totalWeight = 0;
    for (NSDictionary *subprogressWeight in self.subprogressesWeights) {
        totalWeight += [subprogressWeight[subprogressWeightKey] floatValue];
    }
    
    CGFloat total = 0;
    for (NSDictionary *subprogressWeight in self.subprogressesWeights) {
        PDKTProgress *subprogress = subprogressWeight[subprogressKey];
        CGFloat subprogressWeightPercentage = (totalWeight * [subprogressWeight[subprogressWeightKey] floatValue])/100;
        total += (subprogressWeightPercentage/100)*subprogress.progress;
    }
    return total;
}
- (CGFloat)progressBasedOnEquallyWeightedSubprogresses{
    CGFloat total = 0;
    for (NSDictionary *subprogressWeight in self.subprogressesWeights) {
        PDKTProgress *subprogress = subprogressWeight[subprogressKey];
        total += (1/(CGFloat)self.subprogressesWeights.count)*subprogress.progress;
    }
    return total;
}
@end
