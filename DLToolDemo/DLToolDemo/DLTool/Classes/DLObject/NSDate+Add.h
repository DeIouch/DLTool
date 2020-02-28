#import <Foundation/Foundation.h>

@interface NSDate (Add)

@property (nonatomic, readonly) NSInteger year;
@property (nonatomic, readonly) NSInteger month;
@property (nonatomic, readonly) NSInteger day;
@property (nonatomic, readonly) NSInteger hour;
@property (nonatomic, readonly) NSInteger minute;
@property (nonatomic, readonly) NSInteger second;
@property (nonatomic, readonly) NSInteger nanosecond;
@property (nonatomic, readonly) NSInteger weekday;
@property (nonatomic, readonly) NSInteger weekdayOrdinal;
@property (nonatomic, readonly) NSInteger weekOfMonth;
@property (nonatomic, readonly) NSInteger weekOfYear;
@property (nonatomic, readonly) NSInteger yearForWeekOfYear;
@property (nonatomic, readonly) NSInteger quarter;
@property (nonatomic, readonly) BOOL isLeapMonth;
@property (nonatomic, readonly) BOOL isLeapYear;
@property (nonatomic, readonly) BOOL isToday;
@property (nonatomic, readonly) BOOL isYesterday;

-(NSDate *)dl_dateByAddingYears:(NSInteger)years;

-(NSDate *)dl_dateByAddingMonths:(NSInteger)months;

-(NSDate *)dl_dateByAddingWeeks:(NSInteger)weeks;

-(NSDate *)dl_dateByAddingDays:(NSInteger)days;

-(NSDate *)dl_dateByAddingHours:(NSInteger)hours;

-(NSDate *)dl_dateByAddingMinutes:(NSInteger)minutes;

-(NSDate *)dl_dateByAddingSeconds:(NSInteger)seconds;

-(NSString *)dl_stringWithFormat:(NSString *)format;

-(NSString *)dl_stringWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone locale:(NSLocale *)locale;

-(NSString *)dl_stringWithISOFormat;

+(NSDate *)dl_dateWithString:(NSString *)dateString format:(NSString *)format;

+(NSDate *)dl_dateWithString:(NSString *)dateString format:(NSString *)format timeZone:(NSTimeZone *)timeZone locale:(NSLocale *)locale;

+(NSDate *)dl_dateWithISOFormatString:(NSString *)dateString;


@end
