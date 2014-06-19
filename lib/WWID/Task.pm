class WWID::Task {
    has Date $!add-date;
    has int $!value;
    has int $!effort;
    has Str $!project;
    has Str @!tags;
}
