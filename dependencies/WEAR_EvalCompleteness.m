function completeness = WEAR_EvalCompleteness(data)

args = WEAR_getDefaultArgs();
completeness = struct();

for d = fieldnames(data)'
    disp(append('[', datestr(datetime), '] [', d{:}, '] Assess data completeness.'));
    for m = fieldnames(data.(d{:}))'

        if ~any(strcmp(fieldnames(args.(d{:}).fs), m)); continue; end

        m_start = data.(d{:}).(m{:})(1,1);
        m_end = data.(d{:}).(m{:})(end,1);
        m_duration_sec = m_end - m_start;
        m_fs = args.(d{:}).fs.(m{:});

        m_expected = m_fs * m_duration_sec;
        m_recorded = size(data.(d{:}).(m{:}),1);

        completeness.(d{:}).(m{:}).duration_sec = m_duration_sec;
        completeness.(d{:}).(m{:}).exp_samples = m_expected;
        completeness.(d{:}).(m{:}).rec_samples = m_recorded;
        completeness.(d{:}).(m{:}).score = m_recorded/m_expected;
    end
end

end


