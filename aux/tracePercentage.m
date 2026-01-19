function [times] = tracePercentage(step, overall, times)
    global cfg;

	percent=round(overall/cfg.out_width_);

    if mod(step, percent) == 0,
        times=times+1;
        val=floor(double(percent)/double(overall)*100)*times;
        if val < 10, debug_printf(cfg.debug_level_, '0'); end
        debug_printf(cfg.debug_level_, sprintf('%d%%%%... ', val));
        if mod(times, 10) == 0, debug_printf(cfg.debug_level_, '\n'); end
    end
end
