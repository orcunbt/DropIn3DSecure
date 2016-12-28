#import <UIKit/UIKit.h>

#import "BTUIKCardType.h"
#import "BTUIKUtil.h"

#define kDefaultFormatSpaceIndices @[@4, @8, @12, @16]
#define kDefaultCvvLength          3
#define kDefaultValidNumberLengths [NSIndexSet indexSetWithIndex:16]
#define kInvalidCvvCharacterSet    [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]


@implementation BTUIKCardType

#pragma mark - Private initializers

- (instancetype)initWithBrand:(NSString *)brand
             securityCodeName:(NSString *)securityCodeName
                     prefixes:(NSArray *)prefixes
{
    return [self initWithBrand:brand
              securityCodeName:securityCodeName
                      prefixes:prefixes
            validNumberLengths:kDefaultValidNumberLengths
                validCvvLength:kDefaultCvvLength
                  formatSpaces:kDefaultFormatSpaceIndices];
}

- (instancetype)initWithBrand:(NSString *)brand
             securityCodeName:(NSString *)securityCodeName
                     prefixes:(NSArray *)prefixes
           validNumberLengths:(NSIndexSet *)validLengths
               validCvvLength:(NSUInteger)cvvLength
                 formatSpaces:(NSArray *)formatSpaces
{
    self = [super init];
    if (self != nil) {
        _brand = brand;
        NSError *error;

        _validNumberPrefixes = prefixes;
        if (error != nil) {
            NSLog(@"Braintree-Payments-UIKit: %@", error);
        }
        _validNumberLengths = validLengths;
        _validCvvLength = cvvLength;

        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]];
        _formatSpaces = [formatSpaces sortedArrayUsingDescriptors:sortDescriptors] ?: kDefaultFormatSpaceIndices;
        _maxNumberLength = [validLengths lastIndex];
        _securityCodeName = securityCodeName;
    }
    return self;
}

#pragma mark - Finders

+ (instancetype)cardTypeForBrand:(NSString *)rename {
    return [[self class] cardsByBrand][rename];
}

+ (instancetype)cardTypeForNumber:(NSString *)number {
    if (number.length == 0) {
        return nil;
    }
    for (BTUIKCardType *cardType in [[self class] allCards]) {
        for (NSString *prefix in cardType.validNumberPrefixes) {
            if (number.length >= prefix.length) {
                NSUInteger compareLength = MIN(prefix.length, number.length);
                NSString *sizedNumber = [number substringToIndex:compareLength];
                if ([sizedNumber isEqualToString:prefix]) {
                    return cardType;
                }
            }
        }
    }
    return nil;
}

// Since each card type has a list of acceptable card prefixes, we
// can determine which card types may match a given number
+ (NSArray *)possibleCardTypesForNumber:(NSString *)number {
    number = [BTUIKUtil stripNonDigits:number];
    if (number.length == 0) {
        return [[self class] allCards];
    }
    NSMutableSet *possibleCardTypes = [NSMutableSet set];
    for (BTUIKCardType *cardType in [[self class] allCards]) {
        for (NSString *prefix in cardType.validNumberPrefixes) {
            NSUInteger compareLength = MIN(prefix.length, number.length);

            NSString *sizedPrefix = [prefix substringToIndex:compareLength];
            NSString *sizedNumber = [number substringToIndex:compareLength];
            if ([sizedNumber isEqualToString:sizedPrefix]) {
                [possibleCardTypes addObject:cardType];
                break;
            }
        }
    }
    return [possibleCardTypes allObjects];
}

#pragma mark - Instance methods

- (BOOL)validCvv:(NSString *)cvv {
    if (cvv.length != self.validCvvLength) {
        return NO;
    }
    return ([cvv rangeOfCharacterFromSet:kInvalidCvvCharacterSet].location == NSNotFound);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BTUIKCardType %@", self.brand];
}

#pragma mark - Immutable singletons

+ (NSUInteger)maxNumberLength {
    static dispatch_once_t p = 0;
    static NSUInteger _maxNumberLength = 0;
    dispatch_once(&p, ^{
        for (BTUIKCardType *t in [self allCards]) {
            _maxNumberLength = MAX(_maxNumberLength, t.maxNumberLength);
        }
    });
    return _maxNumberLength;
}

+ (NSArray *)allCards
{
    static dispatch_once_t p = 0;
    static NSArray *_allCards = nil;

    dispatch_once(&p, ^{

        BTUIKCardType *visa = [[BTUIKCardType alloc] initWithBrand:BTUIKLocalizedString(CARD_TYPE_VISA)
                                                  securityCodeName:BTUIKLocalizedString(CVV_FIELD_PLACEHOLDER)
                                                          prefixes:@[@"4"]];
        BTUIKCardType *mastercard = [[BTUIKCardType alloc] initWithBrand:BTUIKLocalizedString(CARD_TYPE_MASTER_CARD)
                                                        securityCodeName:BTUIKLocalizedString(CVC_FIELD_PLACEHOLDER)
                                                              prefixes:@[@"51", @"52", @"53", @"54", @"55"]];
        BTUIKCardType *discover = [[BTUIKCardType alloc] initWithBrand:BTUIKLocalizedString(CARD_TYPE_DISCOVER)
                                                      securityCodeName:BTUIKLocalizedString(CID_FIELD_PLACEHOLDER)
                                                              prefixes:@[@"6011", @"65", @"644", @"645", @"646", @"647", @"648", @"649"]];
        BTUIKCardType *jcb = [[BTUIKCardType alloc] initWithBrand:BTUIKLocalizedString(CARD_TYPE_JCB)
                                                 securityCodeName:BTUIKLocalizedString(CVV_FIELD_PLACEHOLDER)
                                                         prefixes:@[@"35"]];
        BTUIKCardType *amex = [[BTUIKCardType alloc] initWithBrand:BTUIKLocalizedString(CARD_TYPE_AMERICAN_EXPRESS)
                                                  securityCodeName:BTUIKLocalizedString(CID_FIELD_PLACEHOLDER)
                                                        prefixes:@[@"34", @"37"]
                                              validNumberLengths:[NSIndexSet indexSetWithIndex:15]
                                                  validCvvLength:4
                                                    formatSpaces:@[@4, @10]];
        BTUIKCardType *dinersClub = [[BTUIKCardType alloc] initWithBrand:BTUIKLocalizedString(CARD_TYPE_DINERS_CLUB)
                                                        securityCodeName:BTUIKLocalizedString(CVV_FIELD_PLACEHOLDER)
                                                              prefixes:@[@"36", @"38", @"300", @"301", @"302", @"303", @"304", @"305"]
                                                    validNumberLengths:[NSIndexSet indexSetWithIndex:14]
                                                        validCvvLength:3
                                                          formatSpaces:nil];
        BTUIKCardType *maestro = [[BTUIKCardType alloc] initWithBrand:BTUIKLocalizedString(CARD_TYPE_MAESTRO)
                                                     securityCodeName:BTUIKLocalizedString(CVC_FIELD_PLACEHOLDER)
                                                           prefixes:@[@"5018", @"5020", @"5038", @"6020", @"6304", @"6759", @"6761", @"6762", @"6763"]
                                                 validNumberLengths:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 8)]
                                                     validCvvLength:3
                                                       formatSpaces:nil];
        BTUIKCardType *unionPay = [[BTUIKCardType alloc] initWithBrand:BTUIKLocalizedString(CARD_TYPE_UNION_PAY)
                                                      securityCodeName:BTUIKLocalizedString(CVN_FIELD_PLACEHOLDER)
                                                            prefixes:@[@"62"]
                                                  validNumberLengths:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(16, 4)]
                                                      validCvvLength:3
                                                        formatSpaces:nil];

        _allCards = @[visa, mastercard, discover, amex, dinersClub, jcb, mastercard, maestro, unionPay];
    });

    // returns the same object each time
    return _allCards;
}

+ (NSDictionary *)cardsByBrand {
    static dispatch_once_t p = 0;
    static NSDictionary *_cardsByBrand = nil;

    dispatch_once(&p, ^{
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (BTUIKCardType *cardType in [self allCards]) {
            d[cardType.brand] = cardType;
        }
        _cardsByBrand = d;
    });
    return _cardsByBrand;
}

#pragma mark - Formatting

- (NSAttributedString *)formatNumber:(NSString *)input kerning:(CGFloat)kerning{
    input = [BTUIKUtil stripNonDigits:input];

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:input];

    if (input.length > 20) {
        return result;
    }

    for (NSNumber *indexNumber in self.formatSpaces) {
        NSUInteger index = [indexNumber unsignedIntegerValue];
        if (index >= result.length) {
            break;
        }
        [result setAttributes:@{NSKernAttributeName: @(kerning)} range:NSMakeRange(index-1, 1)];
    }
    return result;
}

- (NSAttributedString *)formatNumber:(NSString *)input {
    return [self formatNumber:input kerning:8.0f];
}

#pragma mark - Validation

- (BOOL)validAndNecessarilyCompleteNumber:(NSString *)number {
    return (number.length == self.validNumberLengths.lastIndex &&
            ([BTUIKUtil luhnValid:number] || [self.brand isEqualToString:BTUIKLocalizedString(CARD_TYPE_UNION_PAY)]));
}

- (BOOL)validNumber:(NSString *)number {
    return ([self completeNumber:number] &&
            ([BTUIKUtil luhnValid:number] || [self.brand isEqualToString:BTUIKLocalizedString(CARD_TYPE_UNION_PAY)]));
}

- (BOOL)completeNumber:(NSString *)number {
    return [self.validNumberLengths containsIndex:number.length];
}



@end
