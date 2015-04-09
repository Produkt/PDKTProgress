//
//  TestableTHProgressHandler.h
//  Thoughts
//
//  Created by Daniel García García on 6/2/15.
//  Copyright (c) 2015 Produkt. All rights reserved.
//

#import "PDKTProgress.h"

@interface TestablePDKTProgress : PDKTProgress
@property (assign,nonatomic,readwrite) CGFloat fakeProgressLimit;
@property (assign,nonatomic,readwrite) CGFloat fakeProgressIncrement;
@end
