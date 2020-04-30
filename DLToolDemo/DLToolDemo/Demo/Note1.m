#import "Note1.h"

@implementation Note1

@end


/*
 
isa

isa指针用来维护 “对象” 和 “类” 之间的关系，并确保对象和类能够通过isa指针找到对应的方法、实例变量、属性、协议等；
在 arm64 架构之前，isa就是一个普通的指针，直接指向objc_class，存储着Class、Meta-Class对象的内存地址。instance对象的isa指向class对象，class对象的isa指向meta-class对象；
从 arm64 架构开始，对isa进行了优化，用nonpointer表示，变成了一个共用体（union）结构，还使用位域来存储更多的信息。将 64 位的内存数据分开来存储着很多的东西，其中的 33 位才是拿来存储class、meta-class对象的内存地址信息。要通过位运算将isa的值& ISA_MASK掩码，才能得到class、meta-class对象的内存地址。
 
 如果isa非nonpointer，即 arm64 架构之前的isa指针。由于它只是一个普通的指针，存储着Class、Meta-Class对象的内存地址，所以它本身不能存储引用计数，所以以前对象的引用计数都存储在一个叫SideTable结构体的RefCountMap（引用计数表）散列表中。
 如果isa是nonpointer，则它本身可以存储一些引用计数。从以上union isa_t的定义中我们可以得知，isa_t中存储了两个引用计数相关的东西：extra_rc和has_sidetable_rc。

 extra_rc：里面存储的值是对象本身之外的引用计数的数量，这 19 位如果不够存储，has_sidetable_rc的值就会变为 1；
 has_sidetable_rc：如果为 1，代表引用计数过大无法存储在isa中，那么超出的引用计数会存储SideTable的RefCountMap中。

 所以，如果isa是nonpointer，则对象的引用计数存储在它的isa_t的extra_rc中以及SideTable的RefCountMap中。
 
 
 
 */
