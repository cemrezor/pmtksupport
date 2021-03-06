function p = prior_t(do, varargin)
% PRIOR_T     Student-t prior structure     
%       
%        Description
%        P = PRIOR_T('INIT') returns a structure that specifies Student's
%        t-distribution prior. 
%
%        Parameterisation is done by Bayesian Data Analysis,  
%        second edition, Gelman et.al 2004.
%    
%	The fields in P are:
%           p.type         = 'Student-t'
%           p.mu           = Location (default 0)
%           p.s2           = Scale (default 1)
%           p.nu           = Degrees of freedom (default 4)
%           p.fh_pak       = Function handle to parameter packing routine
%           p.fh_unpak     = Function handle to parameter unpacking routine
%           p.fh_e         = Function handle to energy evaluation routine
%           p.fh_g         = Function handle to gradient of energy evaluation routine
%           p.fh_recappend = Function handle to MCMC record appending routine
%
%	P = PRIOR_T('SET', P, 'FIELD1', VALUE1, 'FIELD2', VALUE2, ...)
%       Set the values of fields FIELD1... to the values VALUE1... in LIKELIH. 
%       Fields that can be set: 'mu', 's2', 'nu', 'mu_prior', 's2_prior',
%       'nu_prior'.
%
%	See also
%       PRIOR_GAMMA, PRIOR_NORMAL, PRIOR_SINVCHI2, GPCF_SEXP, LIKELIH_PROBIT

    
% Copyright (c) 2000-2001 Aki Vehtari
% Copyright (c) 2009 Jarno Vanhatalo
% Copyright (c) 2010 Jaakko Riihimäki

% This software is distributed under the GNU General Public
% License (version 2 or later); please refer to the file
% License.txt, included with the software, for details.

    
    if nargin < 1
        error('Not enough arguments')
    end

    % Initialize the prior structure
    if strcmp(do, 'init')
        p.type = 'Student-t';
        
        % set functions
        p.fh_pak = @prior_t_pak;
        p.fh_unpak = @prior_t_unpak;
        p.fh_e = @prior_t_e;
        p.fh_g = @prior_t_g;
        p.fh_recappend = @prior_t_recappend;
        
        % set parameters
        p.mu = 0;
        p.s2 = 1;
        p.nu = 4;
        
        % set parameter priors
        p.p.mu = [];
        p.p.s2 = [];
        p.p.nu = [];
        
        if nargin > 1
            if mod(nargin-1,2) ~=0
                error('Wrong number of arguments')
            end
            % Loop through all the parameter values that are changed
            for i=1:2:length(varargin)-1
                switch varargin{i}
                  case 'mu'
                    p.mu = varargin{i+1};
                  case 's2'
                    p.s2 = varargin{i+1};
                  case 'nu'
                    p.nu = varargin{i+1};
                  case 'mu_prior'
                    p.p.mu = varargin{i+1};
                  case 's2_prior'
                    p.p.s2 = varargin{i+1};
                  case 'nu_prior'
                    p.p.nu = varargin{i+1};                    
                  otherwise
                    error('Wrong parameter name!')
                end
            end
        end

    end
    
    % Set the parameter values of the prior
    if strcmp(do, 'set')
        if mod(nargin,2) ~=0
            error('Wrong number of arguments')
        end
        p = varargin{1};
        % Loop through all the parameter values that are changed
        for i=2:2:length(varargin)-1
            switch varargin{i}
              case 'mu'
                p.mu = varargin{i+1};
              case 's2'
                p.s2 = varargin{i+1};
              case 'nu'
                p.nu = varargin{i+1};
              otherwise
                error('Wrong parameter name!')
            end
        end
    end

    
    function w = prior_t_pak(p)
        
        w = [];
        if ~isempty(p.p.mu)
            w = p.mu;
        end        
        if ~isempty(p.p.s2)
            w = [w log(p.s2)];
        end
         if ~isempty(p.p.nu)
            w = [w log(p.nu)];
        end
    end
    
    function [p, w] = prior_t_unpak(p, w)
        
        if ~isempty(p.p.mu)
            i1=1;
            p.mu = w(i1);
            w = w(i1+1:end);
        end
        if ~isempty(p.p.s2)
            i1=1;
            p.s2 = exp(w(i1));
            w = w(i1+1:end);
        end
        if ~isempty(p.p.nu)
            i1=1;
            p.nu = exp(w(i1));
            w = w(i1+1:end);
        end
    end
    
    function e = prior_t_e(x, p)
        
        e=sum(-gammaln((p.nu+1)./2) + gammaln(p.nu./2) + 0.5*log(p.nu.*pi.*p.s2) + (p.nu+1)./2.*log(1+(x-p.mu).^2./p.nu./p.s2));
        
        if ~isempty(p.p.mu)
            e = e + feval(p.p.mu.fh_e, p.mu, p.p.mu);
        end
        if ~isempty(p.p.s2)
            e = e + feval(p.p.s2.fh_e, p.s2, p.p.s2) - log(p.s2);
        end
        if ~isempty(p.p.nu)
            e = e + feval(p.p.nu.fh_e, p.nu, p.p.nu)  - log(p.nu);
        end
    end
    
    function g = prior_t_g(x, p)

        g=(p.nu+1)./p.nu .* (x-p.mu)./p.s2 ./ (1 + (x-p.mu).^2./p.nu./p.s2);
        
        if ~isempty(p.p.mu)
        	gmu = sum( -(p.nu+1)./p.nu .* (x-p.mu)./p.s2 ./ (1 + (x-p.mu).^2./p.nu./p.s2) ) + feval(p.p.mu.fh_g, p.mu, p.p.mu);
            g = [g gmu];
        end
        if ~isempty(p.p.s2)
        	gs2 = (sum( 1./(2.*p.s2) - (p.nu+1)./(2*p.nu.*p.s2.^2).*(x-p.mu).^2./(1+(x-p.mu).^2./p.nu./p.s2) ) + feval(p.p.s2.fh_g, p.s2, p.p.s2)).*p.s2 - 1;
            g = [g gs2];
        end
        if ~isempty(p.p.nu)
            gnu = (0.5*sum( -digamma1((p.nu+1)./2)+digamma1(p.nu./2)+1./p.nu+log(1+(x-p.mu).^2./p.nu./p.s2)-(p.nu+1)./(1+(x-p.mu).^2./p.nu./p.s2).*(x-p.mu).^2./p.s2./p.nu.^2) + feval(p.p.nu.fh_g, p.nu, p.p.nu)).*p.nu - 1;
            g = [g gnu];
        end
    end
    
    function rec = prior_t_recappend(rec, ri, p)
    % The parameters are not sampled in any case.
        rec = rec;
        if ~isempty(p.p.mu)
        	rec.mu(ri) = p.mu;
        end        
        if ~isempty(p.p.s2)
        	rec.s2(ri) = p.s2;
        end
        if ~isempty(p.p.nu)
        	rec.nu(ri) = p.nu;
        end
    end
end