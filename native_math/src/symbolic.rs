use std::fmt;

#[derive(Debug, Clone, PartialEq)]
pub enum Expr {
    Num(f64),
    Var(String),
    Add(Box<Expr>, Box<Expr>),
    Sub(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
    Div(Box<Expr>, Box<Expr>),
    Pow(Box<Expr>, Box<Expr>),
    Sin(Box<Expr>),
    Cos(Box<Expr>),
    Tan(Box<Expr>),
    Ln(Box<Expr>),
    Exp(Box<Expr>),
}

#[derive(Debug, Clone, PartialEq)]
enum Token {
    Num(f64),
    Ident(String),
    Plus,
    Minus,
    Star,
    Slash,
    Caret,
    LParen,
    RParen,
}

fn tokenize(input: &str) -> Result<Vec<Token>, String> {
    let mut tokens = Vec::new();
    let chars: Vec<char> = input.chars().collect();
    let mut i = 0;

    while i < chars.len() {
        match chars[i] {
            ' ' | '\t' | '\n' | '\r' => i += 1,
            '+' => {
                tokens.push(Token::Plus);
                i += 1;
            }
            '-' => {
                tokens.push(Token::Minus);
                i += 1;
            }
            '*' => {
                tokens.push(Token::Star);
                i += 1;
            }
            '/' => {
                tokens.push(Token::Slash);
                i += 1;
            }
            '^' => {
                tokens.push(Token::Caret);
                i += 1;
            }
            '(' => {
                tokens.push(Token::LParen);
                i += 1;
            }
            ')' => {
                tokens.push(Token::RParen);
                i += 1;
            }
            c if c.is_ascii_digit() || c == '.' => {
                let start = i;
                while i < chars.len() && (chars[i].is_ascii_digit() || chars[i] == '.') {
                    i += 1;
                }
                let s: String = chars[start..i].iter().collect();
                if let Ok(n) = s.parse::<f64>() {
                    tokens.push(Token::Num(n));
                } else {
                    return Err(format!("Invalid number: {}", s));
                }
            }
            c if c.is_ascii_alphabetic() => {
                let start = i;
                while i < chars.len() && chars[i].is_ascii_alphanumeric() {
                    i += 1;
                }
                let s: String = chars[start..i].iter().collect();
                tokens.push(Token::Ident(s));
            }
            c => return Err(format!("Unexpected character: {}", c)),
        }
    }
    Ok(tokens)
}

struct Parser<'a> {
    tokens: &'a [Token],
    pos: usize,
}

impl<'a> Parser<'a> {
    fn new(tokens: &'a [Token]) -> Self {
        Parser { tokens, pos: 0 }
    }

    fn peek(&self) -> Option<&Token> {
        self.tokens.get(self.pos)
    }

    fn advance(&mut self) -> Option<&Token> {
        let t = self.tokens.get(self.pos);
        self.pos += 1;
        t
    }

    fn parse_expr(&mut self) -> Result<Expr, String> {
        self.parse_add_sub()
    }

    fn parse_add_sub(&mut self) -> Result<Expr, String> {
        let mut node = self.parse_mul_div()?;
        while let Some(t) = self.peek() {
            match t {
                Token::Plus => {
                    self.advance();
                    node = Expr::Add(Box::new(node), Box::new(self.parse_mul_div()?));
                }
                Token::Minus => {
                    self.advance();
                    node = Expr::Sub(Box::new(node), Box::new(self.parse_mul_div()?));
                }
                _ => break,
            }
        }
        Ok(node)
    }

    fn parse_mul_div(&mut self) -> Result<Expr, String> {
        let mut node = self.parse_pow()?;
        while let Some(t) = self.peek() {
            match t {
                Token::Star => {
                    self.advance();
                    node = Expr::Mul(Box::new(node), Box::new(self.parse_pow()?));
                }
                Token::Slash => {
                    self.advance();
                    node = Expr::Div(Box::new(node), Box::new(self.parse_pow()?));
                }
                _ => break,
            }
        }
        Ok(node)
    }

    fn parse_pow(&mut self) -> Result<Expr, String> {
        let mut node = self.parse_primary()?;
        while let Some(t) = self.peek() {
            if let Token::Caret = t {
                self.advance();
                node = Expr::Pow(Box::new(node), Box::new(self.parse_pow()?)); // Right associative
            } else {
                break;
            }
        }
        Ok(node)
    }

    fn parse_primary(&mut self) -> Result<Expr, String> {
        let t = self
            .advance()
            .ok_or("Unexpected end of expression")?
            .clone();
        match t {
            Token::Num(n) => Ok(Expr::Num(n)),
            Token::Ident(name) => {
                // Check if it's a function call
                if let Some(Token::LParen) = self.peek() {
                    self.advance(); // consume LParen
                    let inner = self.parse_expr()?;
                    if let Some(Token::RParen) = self.advance() {
                        match name.as_str() {
                            "sin" => Ok(Expr::Sin(Box::new(inner))),
                            "cos" => Ok(Expr::Cos(Box::new(inner))),
                            "tan" => Ok(Expr::Tan(Box::new(inner))),
                            "ln" => Ok(Expr::Ln(Box::new(inner))),
                            "exp" => Ok(Expr::Exp(Box::new(inner))),
                            "sqrt" => Ok(Expr::Pow(Box::new(inner), Box::new(Expr::Num(0.5)))),
                            _ => Err(format!("Unknown function: {}", name)),
                        }
                    } else {
                        Err("Expected closing parenthesis".to_string())
                    }
                } else {
                    Ok(Expr::Var(name))
                }
            }
            Token::LParen => {
                let expr = self.parse_expr()?;
                if let Some(Token::RParen) = self.advance() {
                    Ok(expr)
                } else {
                    Err("Expected closing parenthesis".to_string())
                }
            }
            Token::Minus => {
                let expr = self.parse_primary()?;
                Ok(Expr::Mul(Box::new(Expr::Num(-1.0)), Box::new(expr)))
            }
            _ => Err(format!("Unexpected token: {:?}", t)),
        }
    }
}

pub fn parse(input: &str) -> Result<Expr, String> {
    let tokens = tokenize(input)?;
    let mut parser = Parser::new(&tokens);
    let expr = parser.parse_expr()?;
    if parser.pos < tokens.len() {
        return Err("Unexpected trailing characters".to_string());
    }
    Ok(expr)
}

impl Expr {
    pub fn simplify(&self) -> Expr {
        match self {
            Expr::Add(a, b) => {
                let a = a.simplify();
                let b = b.simplify();
                match (&a, &b) {
                    (Expr::Num(na), Expr::Num(nb)) => Expr::Num(na + nb),
                    (Expr::Num(0.0), x) => x.clone(),
                    (x, Expr::Num(0.0)) => x.clone(),
                    _ if a == b => Expr::Mul(Box::new(Expr::Num(2.0)), Box::new(a)),
                    _ => Expr::Add(Box::new(a), Box::new(b)),
                }
            }
            Expr::Sub(a, b) => {
                let a = a.simplify();
                let b = b.simplify();
                match (&a, &b) {
                    (Expr::Num(na), Expr::Num(nb)) => Expr::Num(na - nb),
                    (x, Expr::Num(0.0)) => x.clone(),
                    (Expr::Num(0.0), x) => {
                        Expr::Mul(Box::new(Expr::Num(-1.0)), Box::new(x.clone()))
                    }
                    _ if a == b => Expr::Num(0.0),
                    _ => Expr::Sub(Box::new(a), Box::new(b)),
                }
            }
            Expr::Mul(a, b) => {
                let a = a.simplify();
                let b = b.simplify();
                match (&a, &b) {
                    (Expr::Num(na), Expr::Num(nb)) => Expr::Num(na * nb),
                    (Expr::Num(0.0), _) => Expr::Num(0.0),
                    (_, Expr::Num(0.0)) => Expr::Num(0.0),
                    (Expr::Num(1.0), x) => x.clone(),
                    (x, Expr::Num(1.0)) => x.clone(),
                    _ => Expr::Mul(Box::new(a), Box::new(b)),
                }
            }
            Expr::Div(a, b) => {
                let a = a.simplify();
                let b = b.simplify();
                match (&a, &b) {
                    (Expr::Num(na), Expr::Num(nb)) if *nb != 0.0 => Expr::Num(na / nb),
                    (Expr::Num(0.0), _) => Expr::Num(0.0),
                    (x, Expr::Num(1.0)) => x.clone(),
                    _ if a == b => Expr::Num(1.0),
                    _ => Expr::Div(Box::new(a), Box::new(b)),
                }
            }
            Expr::Pow(a, b) => {
                let a = a.simplify();
                let b = b.simplify();
                match (&a, &b) {
                    (Expr::Num(na), Expr::Num(nb)) => Expr::Num(na.powf(*nb)),
                    (_, Expr::Num(0.0)) => Expr::Num(1.0),
                    (x, Expr::Num(1.0)) => x.clone(),
                    (Expr::Num(0.0), _) => Expr::Num(0.0),
                    (Expr::Num(1.0), _) => Expr::Num(1.0),
                    _ => Expr::Pow(Box::new(a), Box::new(b)),
                }
            }
            Expr::Sin(a) => {
                let a = a.simplify();
                if let Expr::Num(n) = a {
                    Expr::Num(n.sin())
                } else {
                    Expr::Sin(Box::new(a))
                }
            }
            Expr::Cos(a) => {
                let a = a.simplify();
                if let Expr::Num(n) = a {
                    Expr::Num(n.cos())
                } else {
                    Expr::Cos(Box::new(a))
                }
            }
            Expr::Tan(a) => {
                let a = a.simplify();
                if let Expr::Num(n) = a {
                    Expr::Num(n.tan())
                } else {
                    Expr::Tan(Box::new(a))
                }
            }
            Expr::Ln(a) => {
                let a = a.simplify();
                if let Expr::Num(n) = a {
                    Expr::Num(n.ln())
                } else {
                    Expr::Ln(Box::new(a))
                }
            }
            Expr::Exp(a) => {
                let a = a.simplify();
                if let Expr::Num(n) = a {
                    Expr::Num(n.exp())
                } else {
                    Expr::Exp(Box::new(a))
                }
            }
            _ => self.clone(),
        }
    }

    pub fn differentiate(&self, var: &str) -> Expr {
        match self {
            Expr::Num(_) => Expr::Num(0.0),
            Expr::Var(v) => {
                if v == var {
                    Expr::Num(1.0)
                } else {
                    Expr::Num(0.0)
                }
            }
            Expr::Add(a, b) => Expr::Add(
                Box::new(a.differentiate(var)),
                Box::new(b.differentiate(var)),
            ),
            Expr::Sub(a, b) => Expr::Sub(
                Box::new(a.differentiate(var)),
                Box::new(b.differentiate(var)),
            ),
            Expr::Mul(a, b) => Expr::Add(
                Box::new(Expr::Mul(Box::new(a.differentiate(var)), b.clone())),
                Box::new(Expr::Mul(a.clone(), Box::new(b.differentiate(var)))),
            ),
            Expr::Div(a, b) => Expr::Div(
                Box::new(Expr::Sub(
                    Box::new(Expr::Mul(Box::new(a.differentiate(var)), b.clone())),
                    Box::new(Expr::Mul(a.clone(), Box::new(b.differentiate(var)))),
                )),
                Box::new(Expr::Pow(b.clone(), Box::new(Expr::Num(2.0)))),
            ),
            Expr::Pow(a, b) => {
                // d/dx(u^v) = u^v * (v' * ln(u) + v * u' / u)
                let u = a.clone();
                let v = b.clone();
                let du = a.differentiate(var);
                let dv = b.differentiate(var);
                Expr::Mul(
                    Box::new(Expr::Pow(u.clone(), v.clone())),
                    Box::new(Expr::Add(
                        Box::new(Expr::Mul(Box::new(dv), Box::new(Expr::Ln(u.clone())))),
                        Box::new(Expr::Mul(v, Box::new(Expr::Div(Box::new(du), u)))),
                    )),
                )
            }
            Expr::Sin(a) => Expr::Mul(
                Box::new(Expr::Cos(a.clone())),
                Box::new(a.differentiate(var)),
            ),
            Expr::Cos(a) => Expr::Mul(
                Box::new(Expr::Mul(
                    Box::new(Expr::Num(-1.0)),
                    Box::new(Expr::Sin(a.clone())),
                )),
                Box::new(a.differentiate(var)),
            ),
            Expr::Tan(a) => Expr::Mul(
                Box::new(Expr::Div(
                    Box::new(Expr::Num(1.0)),
                    Box::new(Expr::Pow(
                        Box::new(Expr::Cos(a.clone())),
                        Box::new(Expr::Num(2.0)),
                    )),
                )),
                Box::new(a.differentiate(var)),
            ),
            Expr::Ln(a) => Expr::Mul(
                Box::new(Expr::Div(Box::new(Expr::Num(1.0)), a.clone())),
                Box::new(a.differentiate(var)),
            ),
            Expr::Exp(a) => Expr::Mul(
                Box::new(Expr::Exp(a.clone())),
                Box::new(a.differentiate(var)),
            ),
        }
    }

    pub fn integrate(&self, var: &str) -> Result<Expr, String> {
        // A very basic rule-based integrator
        match self {
            Expr::Num(n) => Ok(Expr::Mul(
                Box::new(Expr::Num(*n)),
                Box::new(Expr::Var(var.to_string())),
            )),
            Expr::Var(v) => {
                if v == var {
                    Ok(Expr::Div(
                        Box::new(Expr::Pow(
                            Box::new(Expr::Var(v.clone())),
                            Box::new(Expr::Num(2.0)),
                        )),
                        Box::new(Expr::Num(2.0)),
                    ))
                } else {
                    Ok(Expr::Mul(
                        Box::new(Expr::Var(v.clone())),
                        Box::new(Expr::Var(var.to_string())),
                    ))
                }
            }
            Expr::Add(a, b) => Ok(Expr::Add(
                Box::new(a.integrate(var)?),
                Box::new(b.integrate(var)?),
            )),
            Expr::Sub(a, b) => Ok(Expr::Sub(
                Box::new(a.integrate(var)?),
                Box::new(b.integrate(var)?),
            )),
            Expr::Mul(a, b) => {
                // Handle constant multiples: c * f(x)
                if let Expr::Num(n) = **a {
                    return Ok(Expr::Mul(
                        Box::new(Expr::Num(n)),
                        Box::new(b.integrate(var)?),
                    ));
                }
                if let Expr::Num(n) = **b {
                    return Ok(Expr::Mul(
                        Box::new(Expr::Num(n)),
                        Box::new(a.integrate(var)?),
                    ));
                }
                Err("Integration of product not supported (requires integration by parts)".into())
            }
            Expr::Pow(a, b) => {
                if let Expr::Var(v) = &**a {
                    if v == var {
                        if let Expr::Num(n) = **b {
                            if (n - -1.0).abs() < 1e-6 {
                                return Ok(Expr::Ln(Box::new(Expr::Var(var.to_string()))));
                            } else {
                                return Ok(Expr::Div(
                                    Box::new(Expr::Pow(
                                        Box::new(Expr::Var(var.to_string())),
                                        Box::new(Expr::Num(n + 1.0)),
                                    )),
                                    Box::new(Expr::Num(n + 1.0)),
                                ));
                            }
                        }
                    }
                }
                Err("Complex power integration not supported".into())
            }
            Expr::Sin(a) => {
                if let Expr::Var(v) = &**a {
                    if v == var {
                        return Ok(Expr::Mul(
                            Box::new(Expr::Num(-1.0)),
                            Box::new(Expr::Cos(Box::new(Expr::Var(v.clone())))),
                        ));
                    }
                }
                Err("Complex trigonometric integration not supported".into())
            }
            Expr::Cos(a) => {
                if let Expr::Var(v) = &**a {
                    if v == var {
                        return Ok(Expr::Sin(Box::new(Expr::Var(v.clone()))));
                    }
                }
                Err("Complex trigonometric integration not supported".into())
            }
            Expr::Exp(a) => {
                if let Expr::Var(v) = &**a {
                    if v == var {
                        return Ok(Expr::Exp(Box::new(Expr::Var(v.clone()))));
                    }
                }
                Err("Complex exponential integration not supported".into())
            }
            _ => Err(format!("Integration of {:?} not supported", self)),
        }
    }
}

impl fmt::Display for Expr {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Expr::Num(n) => write!(f, "{}", n),
            Expr::Var(v) => write!(f, "{}", v),
            Expr::Add(a, b) => write!(f, "({} + {})", a, b),
            Expr::Sub(a, b) => write!(f, "({} - {})", a, b),
            Expr::Mul(a, b) => write!(f, "{} * {}", a, b),
            Expr::Div(a, b) => write!(f, "{} / {}", a, b),
            Expr::Pow(a, b) => write!(f, "({})^{}", a, b),
            Expr::Sin(a) => write!(f, "sin({})", a),
            Expr::Cos(a) => write!(f, "cos({})", a),
            Expr::Tan(a) => write!(f, "tan({})", a),
            Expr::Ln(a) => write!(f, "ln({})", a),
            Expr::Exp(a) => write!(f, "exp({})", a),
        }
    }
}
