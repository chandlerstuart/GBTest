global class AP61_CaseScoringQueryBuilderSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {
        AP53_CaseScoringQueryBuilder.buildCaseScoringQuery();
    }
}