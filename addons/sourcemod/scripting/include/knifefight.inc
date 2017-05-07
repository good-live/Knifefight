/*
**
*/
#if defined KF_INCLUDE_included
 #endinput
#endif
#define KF_INCLUDE_included

/*
 * Called when a KF Countdown starts
 *
 * @param terrorist            Terrorist index.
 * @param counter-terrorist    Counter-terrorist index.
 * @param timer                Time in secounds till the fight starts.
 * @return Return Plugin_Stop to prevent the countdown.
 */
forward void KF_OnCountdownStart(int terrorist, counter-terrorist, timer);

/*
 * Called when a KF starts
 *
 * @param terrorist            Terrorist index.
 * @param counter-terrorist    Counter-terrorist index.
 * @return Return Plugin_Stop to prevent the countdown.
 */
forward void KF_OnFightStart(int terrorist, counter-terrorist);

/*
 * Called when a KF ends
 *
 * @param terrorist            Terrorist index.
 * @param counter-terrorist    Counter-terrorist index.
 * @param looser               The losser (-1 when it's a draw).
 * @return Return Plugin_Stop to prevent the countdown.
 */
forward void g_hKnifeEndForward(int terrorist, counter-terrorist, looser);
